#!/usr/bin/env bats

setup() {
  # shellcheck source=docker/fetch-moodle.sh
  source docker/fetch-moodle.sh
}

@test "Docker build defaults pin Moodle 5.2.4 and derive the series" {
  run grep -Fx "ARG MOODLE_VERSION=5.2.4" Dockerfile
  [ "${status}" -eq 0 ]

  run grep -Fx "ARG MOODLE_SERIES=" Dockerfile
  [ "${status}" -eq 0 ]

  run grep -F 'fetch-moodle.sh "${MOODLE_VERSION}" /app/public' Dockerfile
  [ "${status}" -eq 0 ]
}

@test "Compose build args default to Moodle 5.2.4" {
  run grep -Fx "        MOODLE_VERSION: \${MOODLE_VERSION:-5.2.4}" compose.yml
  [ "${status}" -eq 0 ]

  run grep -Fx "        MOODLE_SERIES: \${MOODLE_SERIES:-}" compose.yml
  [ "${status}" -eq 0 ]

  run grep -Fx "        MOODLE_SHA256: \${MOODLE_SHA256:-}" compose.yml
  [ "${status}" -eq 0 ]
}

@test "Dockerfile supports both Moodle web-root layouts" {
  run grep -F 'if [ -d /app/public/public ]; then' Dockerfile
  [ "${status}" -eq 0 ]

  run grep -F 'root * {$MOODLE_WEB_ROOT:/app/public/public}' docker/Caddyfile
  [ "${status}" -eq 0 ]

  run grep -F 'MOODLE_WEB_ROOT="${MOODLE_WEB_ROOT:-}"' docker/entrypoint.sh
  [ "${status}" -eq 0 ]
}

@test "series is derived from the release number" {
  [ "$(moodle_series_for 5.2.4)" = "stable502" ]
  [ "$(moodle_series_for 5.3.0)" = "stable503" ]
  [ "$(moodle_series_for 5.3)" = "stable503" ]
  [ "$(moodle_series_for 4.4.2)" = "stable404" ]
  [ "$(moodle_series_for 5.10.1)" = "stable510" ]
}

@test "series derivation rejects non-release strings" {
  run moodle_series_for 5.2.4+
  [ "${status}" -ne 0 ]

  run moodle_series_for latest
  [ "${status}" -ne 0 ]
}

@test "X.Y.0 releases use Moodle's patchless package name" {
  [ "$(moodle_package_name_for 5.3.0)" = "moodle-5.3.tgz" ]
  [ "$(moodle_package_name_for 5.3)" = "moodle-5.3.tgz" ]
  [ "$(moodle_package_name_for 5.2.4)" = "moodle-5.2.4.tgz" ]
  [ "$(moodle_package_name_for 5.10.0)" = "moodle-5.10.tgz" ]
}

@test "Moodle 5.2.4 and 5.3.0 packages are pinned by checksum" {
  [ "$(moodle_known_sha256_for 5.2.4)" = "8569b63f1e97416ecb67ec75767dd20675892c7a62a5e90d1647366fddf873cf" ]
  [ "$(moodle_known_sha256_for 5.3.0)" = "7e5edf110555956571f40e42acffde0eb23681ebebd212a2fec0fe7d795dd511" ]
  [ "$(moodle_known_sha256_for 5.3)" = "7e5edf110555956571f40e42acffde0eb23681ebebd212a2fec0fe7d795dd511" ]

  run moodle_known_sha256_for 5.2.2
  [ "${status}" -ne 0 ]
}

@test "downloads fall back from download.moodle.org to packaging.moodle.org" {
  [ "${MOODLE_MIRRORS[0]}" = "https://download.moodle.org/download.php/direct" ]
  [ "${MOODLE_MIRRORS[1]}" = "https://packaging.moodle.org" ]
}

@test "fetch refuses a package whose checksum does not match" {
  tmp="$(mktemp -d)"
  mkdir -p "${tmp}/src/moodle"
  echo payload >"${tmp}/src/moodle/version.php"
  tar -czf "${tmp}/moodle.tgz" -C "${tmp}/src" moodle

  run moodle_fetch 5.2.4 "${tmp}/out" "" "file://${tmp}/moodle.tgz" "0000000000000000000000000000000000000000000000000000000000000000"
  [ "${status}" -ne 0 ]
  [[ "${output}" == *"checksum does not match"* ]]
  [ ! -e "${tmp}/out/version.php" ]

  rm -rf "${tmp}"
}

@test "fetch unpacks a package whose checksum matches" {
  command -v sha256sum >/dev/null || skip "sha256sum not installed"
  tmp="$(mktemp -d)"
  mkdir -p "${tmp}/src/moodle"
  echo payload >"${tmp}/src/moodle/version.php"
  tar -czf "${tmp}/moodle.tgz" -C "${tmp}/src" moodle
  sum="$(sha256sum "${tmp}/moodle.tgz" | cut -d' ' -f1)"

  run moodle_fetch 5.2.4 "${tmp}/out" "" "file://${tmp}/moodle.tgz" "${sum}"
  [ "${status}" -eq 0 ]
  [ "$(cat "${tmp}/out/version.php")" = "payload" ]

  rm -rf "${tmp}"
}
