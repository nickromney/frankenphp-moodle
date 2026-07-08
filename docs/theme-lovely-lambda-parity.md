# theme_lovely — Lambda feature parity matrix

This document is the honest attestation of how the bundled `theme_lovely` (v1.2.0,
`2026070811`) compares, feature by feature, against the commercial **Lambda** Moodle theme
(RedPi Themes — <https://lambda.redpithemes.com/>). The feature list below was compiled from
Lambda's public documentation and demo sites. Everything marked **Full** or **Equivalent**
was implemented from scratch for this theme and verified against a running Moodle 5.2.1
install — no Lambda code, CSS, templates, images, or text was copied or fetched.

**Statuses**

| Status | Meaning |
|---|---|
| Full | Same feature, same behaviour. |
| Equivalent | Same user-facing outcome via a different (usually simpler or more privacy-preserving) mechanism; the difference is described. |
| Core Moodle | Lambda advertises it, but stock Moodle 5.x already provides it; the theme inherits/styles it rather than reimplementing it. |
| Out of scope | Belongs to Lambda's separate companion plugins, not the theme. |

## Summary counts

- Full: **39**
- Equivalent: **10**
- Core Moodle: **8**
- Out of scope (companion plugin features): **4**
- Not included: **0**

---

## Site home / front page

| Lambda feature | Status | Notes |
|---|---|---|
| Hero slider (slides with image, heading, caption, link) | **Full** | Up to 16 slides, per-slide image/heading/caption/CTA label+URL, autoplay interval, four height presets, "hide captions on mobile". Bootstrap 5 carousel (bundled with Moodle 5.2 Boost — touch/swipe, controls, indicators included). Graceful: with no images, a brand-gradient hero with the site name renders instead. Settings: *Appearance → Themes → Lovely → Site home*. |
| Up to 16 slides / video slides | **Full** | 16 slides; each may carry an optional MP4/WebM video (muted, looping, `playsinline`), layered over the slide image which doubles as poster and static fallback. Videos never carry an `autoplay` attribute — the theme's `motion` module plays them only when the visitor does not prefer reduced motion, and a visible pause/play control stops both the carousel autoplay and all slide videos with one action (WCAG 2.2.2). |
| Ken Burns / transition effects (slide, fade, scale…) | **Full** | Slide-transition setting: horizontal slide (default), cross-fade, or cross-fade with a slow subtle zoom on the image layer only (captions stay still) — a restrained Ken Burns. All variants fully disabled under `prefers-reduced-motion`. |
| Marketing spots / info boxes row | **Full** | 4 spots, each with Font Awesome icon, heading, text, optional link (whole card clickable). Empty spots skipped. |
| Available courses as cards/tiles | **Full** | Toggle restyles the standard front-page "Available courses" listing into a responsive card grid with full-width course images (CSS only — markup stays core, so search/paging keep working). |
| Course categories as cards/tiles | **Full** | Toggle restyles the front-page category tree's top level into a card grid (CSS only). |
| Blog-style site announcements | **Full** | Toggle card-ifies the news-forum posts on the front page (CSS only). |
| "Clean main region" front page layout | **Equivalent** | The hero/marketing sections render outside the main content box; the standard Moodle front-page sections remain configurable via *Site administration → Front page* (set them to None for a fully "clean" marketing page). |

## Header

| Lambda feature | Status | Notes |
|---|---|---|
| Flexible top bar (contact info, social, login link) | **Full** | Toggle + phone, email, optional social icons (shared with footer config), guest login link. Renders inside the fixed header; page/drawer offsets adjust automatically. Hidden on phones. |
| Sticky header option | **Full** | "Sticky navigation bar" toggle (on by default, matching Boost); off = header scrolls away with the page. |
| Header background colour | **Full** | Colour picker (dark colours; nav text is white). Default: deep shade of the primary. |
| Adjustable logo height | **Full** | Free-value setting (`36px`, `2.5rem`, …), validated before being emitted into CSS. |
| Logo / compact logo / favicon upload | **Core Moodle** | *Site administration → Appearance → Logos*. The theme styles what core provides; it also ships its own favicon/screenshot as defaults. |
| Header layout variants (logo centred, floating…) | **Equivalent** | Three CSS-only variants on Boost's single header structure: default, centred logo (RTL-safe symmetric centring), and compact/minimal. Lambda's fourth "floating" variant is deliberately folded into these — the header markup is never forked, so every Boost-family plugin keeps working; that structural guarantee is the trade-off. |
| Search box in header | **Core Moodle** | Global search box renders in the navbar when enabled in core settings. |
| OAuth2 login buttons | **Core Moodle** | Identity providers configured in core render on the login page/modal area; the theme styles them. |

## Footer

| Lambda feature | Status | Notes |
|---|---|---|
| Footer content columns (1–4) | **Equivalent** | Lambda uses Moodle *block regions* in the footer; Lovely uses four HTML-editor settings rendered as responsive columns. Rationale: footer block regions in a Boost 5.2 child require forking the `drawers` layout used by *every* page (a large upgrade-maintenance burden — exactly what this theme avoids); admin-editable HTML columns deliver the same visible result. Empty columns collapse; all four empty hides the band. |
| Social network icons | **Full** | 8 networks (Facebook, X, Instagram, LinkedIn, YouTube, GitHub, Mastodon, generic website), footer placement, optional top-bar placement. Font Awesome 6 brand icons (bundled with Moodle). |
| Footnote / copyright area | **Full** | HTML-editor setting rendered as the footer's bottom strip. |
| Footer colours | **Equivalent** | One "Footer background colour" picker (text/links stay light for guaranteed contrast) rather than Lambda's five separate footer colour pickers. |
| Scroll-to-top button | **Full** | Toggle (default on). Hand-authored AMD module; instant scroll for `prefers-reduced-motion` users. |

## Colours ("Unlimited Colors")

| Lambda feature | Status | Notes |
|---|---|---|
| Theme main colour | **Full** | "Primary colour" picker (pre-SCSS `$primary`). |
| Secondary colour | **Full** | "Secondary / accent colour" picker (used sparingly by design — badges, highlights). |
| Header / footer background colours | **Full** | See Header/Footer sections. |
| Link colour | **Full** | Picker; empty = primary. AA-contrast guidance in the setting description. |
| Button border radius | **Full** | Five presets (Square → Pill). |
| Body text size | **Full** | Four presets, 15–18 px. |
| Page background image + opacity | **Full** | Page background colour picker, background image upload, and a four-step tint control that overlays the background colour on the image (the "opacity" mechanism, inverted so page-edge contrast stays predictable). Most visible with the boxed layout; applied in wide mode too. |
| Dark mode | **Equivalent** | Site-wide admin toggle that recompiles the theme with a hand-tuned dark palette (every text/background pair AA-verified, ≥ 4.5 : 1). Lambda additionally offers a per-user toggle in the profile menu — not included here; the brief explicitly required only the site-wide variant. Unchanged default brand colours are auto-substituted with dark-safe variants; explicitly customised colours are respected as-is. |
| Sidebar/drawer colour options | **Full** | "Drawer background colour" picker, feeding both Boost's own `$drawer-bg-color` and the theme's drawer surfaces so the course index and block drawers agree. |

## Fonts ("Font Selector")

| Lambda feature | Status | Notes |
|---|---|---|
| Body font selector | **Equivalent** | Lambda offers 21 Google-Fonts-CDN choices; Lovely deliberately never phones home. Choices: system stack (default), **Inter**, **Source Sans 3**, **Lora** — bundled inside the theme as variable WOFF2 files (roman + italic) with their SIL OFL licence texts in `theme/lovely/fonts/` — plus custom upload. This is a privacy-by-design substitution, not a gap. |
| Heading font selector | **Equivalent** | Same choices plus "Same as body" (default). |
| Custom font upload | **Full** | WOFF2/WOFF/TTF upload for body and/or heading font, served through the theme's own pluginfile handler, wired into `@font-face` at compile time. |
| Global body text size | **Full** | See Colours. |
| Heading/body/link colour pickers | **Equivalent** | Link colour is a picker; heading/body text colours are palette-derived to protect contrast guarantees. Raw SCSS available. |
| Linearicons icon pack | **Equivalent** | Linearicons is a proprietary icon font that cannot legally be redistributed inside a GPL theme. Font Awesome 6 Free (bundled by Moodle 5.2 itself — no extra requests) is the substitution: marketing spots accept any FA6 icon name and the theme uses FA6 throughout. |

## Courses / UI

| Lambda feature | Status | Notes |
|---|---|---|
| Course image banner cards (front page / listings) | **Full** | Front-page card grids use the course image as a banner (see Site home). |
| Enrolment page layouts | **Equivalent** | One polished layout (card-ified course summary + enrolment boxes, prominent enrol buttons) rather than Lambda's four variants. |
| Activity prev/next navigation | **Core Moodle** | Core since Moodle 4.0; the theme styles the buttons. |
| Dashboard banner image | **Full** | Upload setting; renders behind the dashboard page heading with a legibility overlay. |
| Dashboard stats block / masonry layouts | **Out of scope** | Block-level features of the Lambda Content Block plugin. Core equivalents: standard dashboard blocks + block drawer. |
| Course title banner modes | **Full** | "Course image header banner" toggle renders the course image (the same image core's course cards use) behind the course page header with a legibility overlay; courses without an image keep the standard header. |
| Activity icon styles | **Full** | Three CSS-only variants: rounded tiles (default), circles, and minimal monochrome (one neutral tile colour for every activity purpose, dark-mode aware). |
| "Boxed" vs "wide" page layout | **Full** | Layout style setting (wide default / boxed). Boxed caps and centres the content column, hero/marketing bands, header contents, and footer contents, adds a lift shadow, and shows the configurable page background around the box. Applied to the content column rather than the page wrapper, so Boost's drawer open/close behaviour, RTL, dark mode, and course editing are untouched. |
| Course sharing buttons | **Out of scope** | Lambda Content Block feature. |

## Login

| Lambda feature | Status | Notes |
|---|---|---|
| Login page navbar | **Core Moodle** | Boost 5.2's login layout intentionally renders no navigation bar (upstream design); the theme keeps that and adds a visible "Back to site" pill on the login page instead. |
| Login page background image | **Full** | Upload setting (pre-existing) with brand-gradient fallback; Boost's stock-photo fallback and its watermark are overridden at matching CSS specificity. |
| Login slideshow | **Full** | Up to 3 images cross-fade via pure-CSS keyframes (8 s per image); single image = no animation; `prefers-reduced-motion` freezes on the first image. |
| Modal login form | **Full** | Toggle. The navbar "Log in" link opens a Bootstrap 5 modal wrapping a real POST to `/login/index.php` with a valid `logintoken` (CSRF) — verified by actually authenticating through it with curl. The link keeps its href, so it degrades to the normal login page without JavaScript. |
| Login form position variants | **Full** | Three positions: right (default), left (split-screen mirrored — flex `row-reverse`, RTL-safe), and centred card over the full background (image, gradient, or video). |
| Hide username/password form (SSO-only) | **Core Moodle** | Moodle 5.2 ships this exact setting: "Show login form" (`showloginform`, *Site administration → Plugins → Authentication*). Verified live: setting it to No removes the username/password inputs from the login page. Note: core hides the form unconditionally — it does not check that an identity provider is configured, so only disable it once SSO works; re-enable any time via `php admin/cli/cfg.php --name=showloginform --set=1`. Attested as core rather than duplicated in the theme. |
| Full-screen video login background | **Full** | MP4/WebM upload plays muted/looping behind the whole login page (works with all three form positions). No `autoplay` attribute — played by the `motion` module only without `prefers-reduced-motion`; the login background image doubles as poster and static fallback, and the brand panel goes transparent so the video shows through. |

## Internationalisation / accessibility

| Lambda feature | Status | Notes |
|---|---|---|
| RTL support | **Full** | All theme SCSS survives Moodle's RTL flipper (verified: the RTL stylesheet compiles cleanly and physical properties flip — e.g. the scroll-to-top button's `right` becomes `left`). Logical properties/`text-align: start` used where appropriate. |
| Multilanguage support | **Full** | Every string lives in `lang/en/theme_lovely.php` (translatable via Moodle's standard language customisation); no hard-coded UI text. |
| Accessibility | **Full** | All light and dark palette pairs AA-verified; visible focus rings; `prefers-reduced-motion` respected by the carousel, login slideshow, scroll-to-top, and global transition kill-switch; slider/marketing sections are labelled landmarks. |

## Companion plugins (explicitly out of scope)

| Lambda component | Status | Notes |
|---|---|---|
| **Lambda Content Block** (slideshows, galleries, pricing tables, event lists as blocks) | **Out of scope** | A separate block plugin product, not part of the theme. Core equivalents: HTML/Text blocks, the theme's hero + marketing sections, and Moodle's card-based course listings. |
| **Lambda Content Editor** (20+ TinyMCE components: accordions, jumbotrons, info boxes…) | **Out of scope** | A separate editor plugin product. Core TinyMCE plus Bootstrap 5 classes (available to any HTML author because the theme is Bootstrap-based) cover most of the same authoring patterns. |

## Other Lambda features

| Lambda feature | Status | Notes |
|---|---|---|
| Custom SCSS textareas | **Full** | Raw initial SCSS + raw SCSS (Advanced tab), same mechanism as Boost. |
| Theme presets | **Full** | Lovely default preset + Boost plain preset + uploadable custom presets. |
| Dashboard reset options | **Core Moodle** | *Site administration → Appearance → Default Dashboard page*. |
| Custom menu | **Core Moodle** | `custommenuitems` renders in Boost's (and therefore Lovely's) navbar. |
| BS4→BS5 converter | **Core Moodle** | Moodle 5.x Boost ships `bs4-compat`; inherited. |
