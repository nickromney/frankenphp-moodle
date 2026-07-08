# theme_lovely — review notes for a second pair of eyes

Context for reviewing the `chore/20260708-moodle-theme` branch. The companion document
[theme-lovely-lambda-parity.md](theme-lovely-lambda-parity.md) is the feature-by-feature
attestation against the commercial Lambda theme; this one is about *how* the work was done,
the decisions baked into it, and where a reviewer should poke hardest.

## How this was built (and why that matters to you)

The theme was written by a Claude Sonnet agent across three rounds, adversarially reviewed
twice by GPT-5.5 (via codex), and visually audited with Playwright screenshots. Every review
round found real defects that the previous round's "verified" claims had missed — the list of
those is the Gotchas section below, and it is the strongest argument for not trusting any
single verification method here either. No Lambda code, CSS, templates, images, or text was
copied; feature behaviour was studied from their public docs and demo only.

## Palette and contrast provenance

The palette is original: deep teal primary `#1B5A6B`, warm neutrals (`#FAF7F2` page /
`#241F19` ink), terracotta accent `#B14A24`, with a hand-tuned dark-mode palette
(`#161D20` bg, `#55AECB` dark-mode primary). Every *enumerated* text/background pair was
checked for WCAG AA (≥ 4.5:1) with a contrast script during the build.

**The known weakness — and a reviewer focus area:** only enumerated pairs were checked. Core
Moodle components that render *inside* themed surfaces bring their own colour classes, and two
of these shipped broken before being caught visually: the navbar brand over Bootstrap's
`.bg-body`, and the edit-mode switch label (muted grey, then `.text-primary` teal-on-teal when
active) on the dark navbar. Both are fixed, but the class of bug is systemic: **when reviewing,
look at interactive states (hover, focus, active, checked) of core components on the navbar,
footer, and dark-mode surfaces** rather than trusting the palette table.

## ADRs (decisions this branch implicitly makes)

1. **One theme, extended** — Lambda parity was built into `theme_lovely` rather than a second
   theme. One theme to maintain; the Docker wiring (`MOODLE_THEME`) stays unchanged.
2. **Boost child, SCSS-first, minimal documented template forks.** Every forked Mustache file
   carries a header naming its Boost 5.2 source. Forks: `theme_boost/navbar`,
   `theme_boost/footer`, `theme_boost/login`, `core/user_menu`, plus original templates for
   hero/spots/topbar/footer-content/login-modal. Template forks are the upgrade-maintenance
   hotspot of this theme: **re-diff them against Boost on every Moodle upgrade.**
3. **Footer columns are admin-HTML settings, not block regions.** Real footer block regions
   would require forking the `drawers` layout used by every page. Documented in the parity doc.
4. **Fonts never phone home.** Inter, Source Sans 3, Lora bundled as variable WOFF2 with their
   OFL licence files, plus custom font upload; no Google Fonts CDN. The shipped theme makes no
   external network requests at all.
5. **Dark mode is a site-wide admin toggle** that recompiles SCSS with a dark palette — not a
   per-user preference. Unchanged default brand colours get dark-safe substitutes at compile
   time; explicitly customised colours are respected as-is.
6. **Boxed layout boxes the content column** (`.main-inner`, hero/marketing bands, header and
   footer *contents*), not `#page` — capping `#page` fights Boost's drawer open/close margins
   that course editing depends on. Trade-off: with a drawer open below ~1440px the drawer sits
   at the viewport edge.
7. **Hand-authored AMD without grunt.** Moodle only loads `amd/build/*.min.js`; the `.min`
   suffix is convention, not enforcement. `scrolltotop` and `motion` are readable hand-written
   AMD with annotated sources in `amd/src/`. If this repo ever gains a Node toolchain, wire the
   standard grunt build instead.
8. **Videos never carry the `autoplay` attribute.** The `motion` AMD module starts them only
   when `prefers-reduced-motion` is off, and one visible pause control stops carousel + videos
   (WCAG 2.2.2).
9. **Security posture:** footer/footnote HTML is cleaned at output (`format_text` without
   `noclean` — a stored `<script>` is stripped; verified with a live probe). Raw SCSS
   settings remain admin-trusted, same as Boost. All media/colour settings that feed compiled
   CSS carry `theme_reset_all_caches` callbacks (pluginfile serves with 60-day public caching,
   so a missing callback means stale media for visitors).
10. **Login page keeps Boost 5.2's no-navbar split screen** (that is stock behaviour, verified
    in Boost source) and adds a "Back to site" pill as the way home.
11. **Container wiring:** the entrypoint runs `admin/cli/upgrade.php --non-interactive` on
    every boot (registers image-shipped plugins on existing DBs), validates `MOODLE_THEME`
    against themes present in the image, and only sets + purges when the value actually
    changes.

## Gotchas (each one cost a debugging round)

- **Bootstrap utilities carry `!important` and silently defeat theme rules.** `.bg-body` made
  the navbar cream for three rounds while CSS assertions passed; `.m-0` broke centred-brand
  margins; `.text-primary` made the active edit-mode label unreadable. If a themed element
  looks wrong, grep its template for utility classes before touching SCSS.
- **Parent-theme SCSS callbacks run before the child's, and specificity beats source order.**
  Boost's `theme_boost_get_extra_scss()` emits `body.pagelayout-login #page .login-layout-left`
  (1-2-1); a bare `.login-layout-left` override loses no matter where it appears. Mirror the
  parent's selector exactly.
- **Mustache comments that contain `}}` terminate at the first `}}`** — the rest of the
  "comment" renders as live template, which double-rendered four sections. Bats test 9 guards
  this; keep example `{{ tags }}` out of comment blocks.
- **Parent-theme template overrides live in `templates/theme_boost/…`**, not `templates/`
  root (`mustache_template_finder` resolution). A misplence override fails silently.
- **`admin/cli/cfg.php` does not fire `set_updatedcallback`.** CLI-driven setting changes need
  an explicit `purge_caches.php`; the web UI fires callbacks normally.
- **Moodle's RTL flipper mirrors physical offsets but not transforms.** `left:50% +
  translateX(-50%)` breaks in RTL; use `left:0; right:0; margin:auto` (or logical properties).
- **`empty('0')` is true in PHP** — the "Square" button-radius value `'0'` was silently
  dropped; the pre-SCSS emitter checks `=== null || === ''` instead.
- **Moodle 5.x layout split:** dirroot is `/app/public`, web root is `/app/public/public`;
  CLI scripts live at `/app/public/admin/cli` (outside the web root), themes at
  `/app/public/public/theme`. Get this wrong and COPYs/entrypoint paths fail confusingly.
- **Fresh CLI installs are private by default** (`forcelogin=1`). Guest-visible front-page
  verification requires flipping it; the demo config does.
- **Known benign warning:** scssphp logs `Found no color leading to 4.5:1 contrast ratio
  against #de4251` during compile — Bootstrap's own `color-contrast()` heuristic, appears with
  any custom palette, non-fatal.
- Local dev quirks: host port 443 may be held by an unrelated kind container (use
  `APP_HTTP_PORT=18080 APP_HTTPS_PORT=18443`), and Docker Hub had multi-minute metadata
  timeouts during this work (base images are cached locally; avoid `--pull`/`--no-cache`).

## Verification status (what was actually done, honestly)

- Fresh `down -v` installs after every round; entrypoint sequence, `php -l` on all theme PHP,
  full-debug (`debug=32767`) page loads with zero notices, bats 16/16, RTL stylesheet compiled
  and flip-inspected.
- ~30 Playwright screenshots actually looked at: front (default/demo/boxed/dark/header
  variants at 3 widths), login (right/left/centered/mobile), course page with banner,
  categories, dashboard, mobile 390px, edit-mode switch off/on in a logged-in session.
- Modal login driven end-to-end in a real browser (clicked open, authenticated, landed on
  `/my/`), proving the JS path.
- Stored-XSS probe against a footer column: script stripped, HTML kept.
- **Not verified:** carousel/Ken-Burns animation *timing* (mechanism verified as
  markup+CSS+JS-loads; nobody filmed it), RTL by actual browsing with an RTL language pack,
  dashboard banner appearance (no image in the resting demo config).

## Where to poke hardest as a reviewer

1. `theme/lovely/lib.php` — 12+ pluginfile fileareas and the SCSS emitters (colour/URL values
   flowing into compiled CSS).
2. `theme/lovely/classes/output/core_renderer.php` — `full_header()` course banner on unusual
   page types (secure layout, activities without a course image, guest access).
3. The four template forks vs their Boost 5.2 originals.
4. `docker/entrypoint.sh` upgrade/theme flow on a *persisted* volume (rebuild over existing DB).
5. Interactive-state contrast on dark surfaces, per the palette section above.
