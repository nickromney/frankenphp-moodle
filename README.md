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
- Moodle `5.2`
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

Open:

```bash
https://moodle.docker.test.127.0.0.1.sslip.io
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

If port `80` or `443` is already in use, override the published ports:

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
