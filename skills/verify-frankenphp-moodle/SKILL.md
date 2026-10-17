# Verify FrankenPHP Moodle

Run make verify to build the current repository source and start a loopback-only
Moodle and MariaDB stack in a run-specific Compose project. Preflight refuses
to launch unless Docker Compose is available, the 25 GiB free-space floor is
met, and the exact build and database image tags are already cached; the
verification never pulls images. The app container is capped at 1 CPU and
1 GiB; MariaDB is capped at 1 CPU and 512 MiB.
The image build defaults to cached layers with build networking disabled; a
missing cached layer fails. For a supervised cold build, explicitly set
`VERIFY_BUILD_NETWORK=default` to allow PHP extension, Moodle and Composer
package downloads. Base images must still be cached: image pulls remain disabled.
Other build network values are refused before state creation or launch. The
selected policy is printed in the plan and retained in `build-policy.txt`.

The browser-facing checks drive the Moodle login DOM in selected Playwright
engines, assert its username and password fields, and load the Lovely theme
stylesheet. Runtime checks
confirm the generated config.php, MariaDB health, at least 400 Moodle tables,
and the repository's verify-moodle.sh acceptance command. The site is bound to
127.0.0.1 on two temporary ports. A unique project name owns its containers,
network, volumes, and built local image; cleanup removes those resources.

Evidence is retained under ${VERIFY_EVIDENCE_ROOT:-${VERIFY_BASE_DIR:-${TMPDIR:-/tmp}/verify-frankenphp-moodle}}/<run-id>.
Compose state is under ${VERIFY_BASE_DIR:-${TMPDIR:-/tmp}/verify-frankenphp-moodle}/<run-id>;
cleanup removes that run's state and keeps build, startup, verification, cleanup,
and container logs. The run does not use the user's Moodle data.

This proves a clean local installation, login page, bundled theme asset, and
database initialization. It does not test account login, course editing, or
upgrading an existing Moodle database.


Browser engines default to Chromium, Firefox and WebKit; set `VERIFY_BROWSERS`
to explicitly narrow the run. See [feature coverage](features/README.md).
The clean-install Compose settings ignore project dotenv and ambient Moodle
installation settings so operator credentials and themes cannot change the recipe.

Firefox requires NSS `certutil`. The runner exports only its app's public Caddy
root certificate, imports it into a fresh Firefox NSS profile under run state,
and verifies HTTPS with `ignore_https_errors=False`. The browser profile is
removed after use; the public root and its logged digest remain as evidence.
No system trust or existing browser profile is changed. Missing certificate or
certutil fails without an insecure fallback. Stylesheet requests use browser
`fetch`, so Firefox checks them with the same run-local trust.

The CLI acceptance child receives `CURL_CA_BUNDLE` scoped to the owned public
Caddy root. Its HTTPS request validates that root without changing caller or
system trust.
