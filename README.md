# frankenphp-moodle

`frankenphp-moodle` builds and runs Moodle on top of [FrankenPHP](https://frankenphp.dev/) and MariaDB with Docker Compose.

This repository provides a first-class container setup:

- a root [`Dockerfile`](Dockerfile) for the FrankenPHP app image
- a root [`compose.yml`](compose.yml) for the app and database stack
- a shared [`verify-moodle.sh`](verify-moodle.sh) script for repeatable health checks

It is for the container runtime itself: image shape, required PHP extensions, Moodle installation flow, and repeatable verification. It is not a Debian or Ubuntu host provisioner.

## Baseline

The current maintained baseline is:

- FrankenPHP with PHP `8.4`
- Moodle `5.2.2`
- MariaDB
- Docker
- HTTPS on `moodle.docker.test.127.0.0.1.sslip.io`

## Quick Start

Start the stack directly:

```bash
docker compose up -d --build
```

Or use the repo targets:

```bash
make up
make baseline
```

`docker compose up` will:

- build the FrankenPHP Moodle image
- download the pinned Moodle release into the image at build time
- start a MariaDB container
- install Moodle automatically on first boot
- serve Moodle on `https://moodle.docker.test.127.0.0.1.sslip.io`

The app container keeps the Moodle code under `/app/public` and serves only `/app/public/public`; there is no local Moodle checkout or bind mount required.

By default the published ports bind only to `127.0.0.1`, not all host interfaces.

`make up` waits until HTTPS answers and then runs TLS preflight: it refuses to print a URL whose leaf certificate is expired or within an hour of expiry. Use the URL it prints, including the port when that is not `443`. If something else already owns `127.0.0.1:443` (for example a Kind cluster), `https://moodle.docker.test.127.0.0.1.sslip.io` without a port is that other service, not Moodle.

Open the URL printed by `make up`, for example:

```bash
https://moodle.docker.test.127.0.0.1.sslip.io:18443
```

Default local admin credentials:

```text
username: admin
password: Adminpass123!
```

Override them with `MOODLE_ADMIN_USER` and `MOODLE_ADMIN_PASSWORD` if you do not want the compose defaults.

To trust the local Caddy root certificate on the host:

```bash
make trust-local-ca
```

If port `80` or `443` is already in use, `make up` and `make baseline` probe the host first and move to a free loopback port (typically `18080`/`18443`). Raw `docker compose up` still defaults to `80`/`443`; override them if you skip the Make targets:

```bash
APP_HTTP_PORT=18080 APP_HTTPS_PORT=18443 docker compose up -d --build
```

That will install Moodle with `https://moodle.docker.test.127.0.0.1.sslip.io:18443` as `wwwroot`. If you need a different hostname or scheme, set `MOODLE_HOST`, `SERVER_NAME`, or `MOODLE_SITE_URL` explicitly.

If you want to expose the site on a specific non-loopback interface instead of `127.0.0.1`, set `APP_BIND_HOST`. For example:

```bash
APP_BIND_HOST=192.168.64.3 \
MOODLE_HOST=moodle.slicer.test.192.168.64.3.sslip.io \
SERVER_NAME=moodle.slicer.test.192.168.64.3.sslip.io \
docker compose up -d --build
```

Browsers with their own trust store, such as Firefox, may still need the exported `root.crt` imported manually after `make trust-local-ca`.

`make baseline` runs the same compose stack and then verifies the running site and database state.

## Themes

This repository bundles a custom theme, [`theme/lovely`](theme/lovely), a Boost child theme
(component `theme_lovely`) with a calmer palette, softer geometry, and a polished login page,
plus a configurable site-home hero slider (up to 16 slides, optional per-slide video,
slide/fade/zoom transitions) and marketing spots, boxed or wide page layout with page
background image, a top bar and header layout variants, a themed footer (content columns,
social icons, footnote, scroll-to-top), site-wide dark mode, locally bundled fonts (Inter,
Source Sans 3, Lora - no CDN requests, OFL-licensed files ship in the theme), custom font
uploads, course image header banners, activity icon style variants, a modal login, login form
position variants, and login background slideshow or video. All options live under
*Site administration > Appearance > Themes > Lovely*. The theme targets verifiable feature
parity with the commercial "Lambda" theme; the honest feature-by-feature matrix (including
what is deliberately different or out of scope) is in
[docs/theme-lovely-lambda-parity.md](docs/theme-lovely-lambda-parity.md).

The theme is copied into the image at `/app/public/public/theme/lovely` during the Docker build
(see the `COPY theme/lovely ...` line in the [`Dockerfile`](Dockerfile)) and is set as the
site's default theme on container start via the `MOODLE_THEME` environment variable (default:
`lovely`):

```bash
MOODLE_THEME=lovely docker compose up -d --build
```

Set `MOODLE_THEME=boost` (or `classic`) to fall back to a stock theme instead. On every start
the entrypoint first runs `php admin/cli/upgrade.php --non-interactive` (so plugins shipped by a
rebuilt image, such as the bundled theme, are registered on existing installs), then applies
`MOODLE_THEME` with `php admin/cli/cfg.php --name=theme --set=...` followed by
`php admin/cli/purge_caches.php` - but only when the value names a theme that actually exists in
the image and differs from the current one. Changing the variable and restarting the stack
(`docker compose up -d`, no rebuild needed) is enough to switch themes on an existing install; a
typo'd theme name logs a warning and leaves the current theme untouched.

To iterate on the theme itself:

1. Edit files under `theme/lovely/`.
2. Rebuild the image so the new files are copied in: `docker compose up -d --build`.
3. Purge caches so Moodle recompiles the theme's SCSS:
   `docker compose exec app php admin/cli/purge_caches.php`.
4. For faster iteration while editing SCSS, turn on **Theme designer mode**
   (Site administration > Appearance > Themes > Theme settings, or
   `php admin/cli/cfg.php --name=themedesignermode --set=1`) so Moodle recompiles CSS on every
   request instead of caching it - remember to turn it back off afterwards, it's not for
   production use.

## Verification

The repository keeps verification separate from image setup. The shared verifier is:

```bash
./verify-moodle.sh --help
```

The baseline runner uses that verifier with compose-aware command overrides so the same checks can be reused in other environments.

## Tests

```bash
make up
make down
make test-smoke-bats
make test-integration-bats
```

- `test-smoke-bats` checks shell validity and the verifier contract.
- `test-integration-bats` runs the full Docker baseline end to end.

## Scope

This repository focuses on:

- a known-good FrankenPHP + Moodle container build
- repeatable local verification
- a practical baseline for future HTTPS, persistence, and packaging work

This repository does not contain:

- Ansible
- Apache or nginx host provisioning
- VM or VPS orchestration

## Notes

Current feasibility notes are in [docs/frankenphp-feasibility.md](docs/frankenphp-feasibility.md).
