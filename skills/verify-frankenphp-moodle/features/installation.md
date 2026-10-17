# Clean installation

## Sub-features

Cached-only build; loopback listeners; login heading and credentials fields;
Lovely stylesheet; generated config; MariaDB health and at least 400 tables;
run-owned container, volume and image cleanup.

## How to get to it (user POV)

Open the run's HTTPS URL at `/login/index.php` to see a new Moodle installation.

## Driving it with verify-frankenphp-moodle

`make verify` launches a unique Compose project and drives Chromium, Firefox and
WebKit by default. `VERIFY_BROWSERS` explicitly narrows the browser scope.
`make verify-test` checks shared contracts and refusal/environment isolation.

## Gotchas

A supervised container environment, 25 GiB free space, cached base images and
Playwright 1.63.0 with its browser cache are prerequisites. The build has no
network by default. Explicit `VERIFY_BUILD_NETWORK=default` permits package
downloads during a supervised cold build; image pulls remain disabled. The clean-install settings ignore project dotenv and ambient Moodle
settings; this does not exercise operator configuration or existing data.

Firefox imports only the run's public Caddy root into a temporary NSS profile
and keeps HTTPS verification enabled. NSS `certutil` is required when Firefox is
selected. No system or shared browser trust changes are made.
