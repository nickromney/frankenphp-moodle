#!/usr/bin/env bats

@test "theme_lovely ships the required Moodle theme plugin files" {
  for f in version.php config.php lib.php settings.php lang/en/theme_lovely.php \
    scss/preset/default.scss pix/screenshot.png; do
    [ -f "theme/lovely/${f}" ]
  done
}

@test "theme_lovely declares its component and Boost as a parent" {
  run grep -F "\$plugin->component = 'theme_lovely';" theme/lovely/version.php
  [ "${status}" -eq 0 ]

  run grep -F "\$THEME->parents = ['boost'];" theme/lovely/config.php
  [ "${status}" -eq 0 ]
}

@test "Dockerfile stages the theme and copies it for both Moodle layouts" {
  for instruction in \
    'COPY theme/lovely /tmp/moodle-theme-lovely' \
    'cp -a /tmp/moodle-theme-lovely /app/public/public/theme/lovely' \
    'cp -a /tmp/moodle-theme-lovely /app/public/theme/lovely' \
    'rm -rf /tmp/moodle-theme-lovely'; do
    run grep -F "${instruction}" Dockerfile
    [ "${status}" -eq 0 ]
  done
}

@test "entrypoint sets the default theme from MOODLE_THEME and purges caches" {
  run grep -F 'MOODLE_THEME="${MOODLE_THEME:-lovely}"' docker/entrypoint.sh
  [ "${status}" -eq 0 ]

  run grep -F 'admin/cli/cfg.php" --name=theme --set="${MOODLE_THEME}"' docker/entrypoint.sh
  [ "${status}" -eq 0 ]

  run grep -F 'admin/cli/purge_caches.php' docker/entrypoint.sh
  [ "${status}" -eq 0 ]
}

@test "compose.yml passes MOODLE_THEME through to the app service" {
  run grep -F "MOODLE_THEME: \${MOODLE_THEME:-lovely}" compose.yml
  [ "${status}" -eq 0 ]
}

@test "theme_lovely ships the Lambda-parity feature files" {
  for f in layout/frontpage.php classes/output/core_renderer.php \
    templates/frontpage.mustache templates/hero.mustache templates/marketingspots.mustache \
    templates/topbar.mustache templates/footer_content.mustache templates/login_modal.mustache \
    templates/theme_boost/navbar.mustache templates/theme_boost/footer.mustache \
    templates/theme_boost/login.mustache templates/login_video.mustache \
    templates/core/user_menu.mustache \
    amd/src/scrolltotop.js amd/build/scrolltotop.min.js \
    amd/src/motion.js amd/build/motion.min.js \
    scss/lovely/topbar.scss scss/lovely/frontpage.scss scss/lovely/enrol.scss \
    scss/lovely/variants.scss; do
    [ -f "theme/lovely/${f}" ]
  done
}

@test "theme_lovely bundles fonts locally with their OFL licenses" {
  for f in InterVariable.woff2 SourceSans3-Variable.woff2 Lora-Variable.woff2 \
    LICENSE-Inter.txt LICENSE-SourceSans3.txt LICENSE-Lora.txt; do
    [ -f "theme/lovely/fonts/${f}" ]
  done

  # Privacy guarantee: the theme must never reference an external font/CDN host.
  run grep -rE "fonts.googleapis|fonts.gstatic|cdn\.|cdnjs|unpkg|jsdelivr" theme/lovely/scss theme/lovely/templates theme/lovely/lib.php
  [ "${status}" -ne 0 ]
}

@test "theme_lovely version is at least the Lambda-parity feature release" {
  version="$(sed -n 's/^\$plugin->version[[:space:]]*=[[:space:]]*\([0-9]\{10\}\);$/\1/p' theme/lovely/version.php)"
  [ -n "${version}" ]
  [ "${version}" -ge 2026070812 ]

  run grep -E "^\\\$plugin->release   = '[0-9]+\.[0-9]+\.[0-9]+ for Moodle 5\.2 and 5\.3';" theme/lovely/version.php
  [ "${status}" -eq 0 ]
}

@test "theme_lovely declares support for Moodle 5.2 and 5.3" {
  run grep -Fx '$plugin->supported = [502, 503];' theme/lovely/version.php
  [ "${status}" -eq 0 ]
}

@test "theme_lovely loads Bootstrap's Carousel from the module each branch ships" {
  run grep -F "'bootstrap' : 'theme_boost/bootstrap/carousel'" theme/lovely/lib.php
  [ "${status}" -eq 0 ]

  run grep -F 'theme_boost/bootstrap/carousel' theme/lovely/amd/build/motion.min.js
  [ "${status}" -ne 0 ]

  run grep -F "Motion.init('{{carouselmodule}}');" theme/lovely/templates/hero.mustache
  [ "${status}" -eq 0 ]
}

@test "theme_lovely frontpage drawer renders course-index controls on 5.2 and 5.3" {
  run grep -F '{{$drawerheadercontent}}' theme/lovely/templates/frontpage.mustache
  [ "${status}" -eq 0 ]

  run grep -F '{{$drawercontrols}}{{> theme_boost/courseindexdrawercontrols}}{{/drawercontrols}}' theme/lovely/templates/frontpage.mustache
  [ "${status}" -eq 0 ]
}

@test "theme_lovely mustache comments contain no live template tags" {
  # A '{{' inside a mustache comment terminates the comment at the first '}}' and the rest
  # renders as template body (this bit us once: sections rendered twice).
  run bash -c '
    for f in $(find theme/lovely/templates -name "*.mustache"); do
      awk "BEGIN{RS=\"}}\"} /\\{\\{!/ { body=\$0; sub(/.*\\{\\{!/, \"\", body); if (body ~ /\\{\\{/) { print FILENAME; exit 1 } }" "$f" || exit 1
    done
  '
  [ "${status}" -eq 0 ]
}

@test "theme_lovely parity matrix has no Not included rows left" {
  run grep -c '| \*\*Not included\*\*' docs/theme-lovely-lambda-parity.md
  [ "${output}" = "0" ]
}

@test "theme_lovely keeps the content column on the surface colour under Boost 5.3" {
  run awk '/^#page\.drawers \.main-inner \{/ { getline; found = ($0 ~ /background-color: \$white;/) } END { exit !found }' theme/lovely/scss/lovely/base.scss
  [ "${status}" -eq 0 ]
}

@test "theme_lovely styles Moodle 5.3's design-system edit switch label on the navbar" {
  run grep -F '.mds-switch-label {' theme/lovely/scss/lovely/navigation.scss
  [ "${status}" -eq 0 ]

  run grep -F 'font-family: inherit;' theme/lovely/scss/lovely/navigation.scss
  [ "${status}" -eq 0 ]
}
