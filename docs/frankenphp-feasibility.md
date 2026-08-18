# FrankenPHP Feasibility

This repo has a rerunnable FrankenPHP baseline for the narrow Docker target, exposed as a root `Dockerfile` plus `compose.yml`:

- PHP `8.4`
- Moodle `5.2.2`
- MariaDB
- HTTPS in Docker via Caddy's local CA

Run it with:

```bash
docker compose up -d --build
```

or:

```bash
tests/docker/run-baseline.sh
```

## What Works

The baseline builds a `dunglas/frankenphp:php8.4-bookworm` image, installs the missing Moodle PHP extensions, starts a MariaDB sidecar, runs the Moodle CLI installer on first boot, and verifies:

- `HTTP 200` from the running HTTPS site
- a live login page
- at least `400` Moodle tables in the database

In local validation, the working run reached `489` Moodle tables.

## What Needed Changing

FrankenPHP was not a drop-in replacement for the existing `nginx` or `apache` branches.

The working container path depends on these FrankenPHP-specific choices:

- use a dedicated image with Moodle extensions added (`gd`, `intl`, `mysqli`, `pdo_mysql`, `soap`, `zip`, `ldap`)
- set PHP `max_input_vars=5000` and `memory_limit=256M`
- install Moodle with `--dbtype=mariadb`
- create the MariaDB database with `utf8mb4_unicode_ci`
- use `tls internal` for `moodle.docker.test.127.0.0.1.sslip.io`, because that host is not eligible for public ACME when it resolves to `127.0.0.1`

That last point matters: MariaDB `11.8` accepts `utf8mb4_uca1400_ai_ci` as a database default, but Moodle's install-time Unicode check does not recognise that value reliably in this container path.

## Why The Split Makes Sense

The old monorepo runtime was shaped around real Debian or Ubuntu VMs:

- `apache` or `nginx`
- optional PHP-FPM
- `systemd` service management
- certbot or self-signed certificate flows
- host-level Prometheus exporters

FrankenPHP is a different runtime model:

- Caddy-based app server, not `nginx` or `apache`
- no PHP-FPM requirement in the normal path
- container-first operational model
- different TLS story
- different monitoring and service-management expectations

Splitting this into `frankenphp-moodle` keeps the container runtime boundary clean instead of forcing those VM assumptions into the FrankenPHP path.
