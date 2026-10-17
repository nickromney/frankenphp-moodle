# Verification evidence

The verification harness builds current source and installs Moodle in a unique, loopback-only Compose project. It caps the app at 1 CPU/1 GiB and MariaDB at 1 CPU/512 MiB. Cached images, pinned Playwright and a 25 GiB disk floor are checked before build. Verification does not pull images. Build networking is disabled by default; explicitly setting `VERIFY_BUILD_NETWORK=default` permits the Dockerfile's dependency downloads.

## Review on 17 October 2026

Upgraded the shared library and contracts to verify-kit 1.3.3. Fixed ambient installation settings leaking into the lab, invalid Compose project names from default run IDs, and the stale browser heading assertion. The browser requires the exact headings rendered by pinned Moodle 5.2.4, credential fields and a successful nonempty Lovely stylesheet response.

Real runs exposed local certificate handling failures. Firefox now imports only the owned app's public Caddy root into a fresh NSS profile under run state and keeps HTTPS verification enabled. The profile is removed after use. The CLI acceptance receives the same public root through a child-only `CURL_CA_BUNDLE`. No system trust or existing browser profile changes. Missing CA or NSS certutil refuses rather than bypassing validation.

Shellcheck and all 39 harness cases passed, including RED/GREEN regressions and Docker-specific refusals without host NSS. Actual Compose configuration also proved isolation from hostile ambient settings and preserved resource caps. Normal repository gates run before publication and through the push hook.

## Actual acceptance

Run `20261017T101026Z-81160-29340-24435` passed the current-source build and clean installation, login page and Lovely stylesheet in Chromium, Firefox and WebKit, generated config, MariaDB ping, 490 installed Moodle tables and `verify-moodle.sh` acceptance. Firefox and CLI HTTPS validation used only the run's CA. The supervised run explicitly enabled build dependency networking after preparing cached images separately and used task-local Playwright 1.63.0 with the existing browser cache.

The result records `VERIFY PASS` and cleanup passed. Run-owned containers, volumes, app image and browser profile were removed; evidence remained. Existing Docker workloads were unchanged. Raw evidence and failed-run diagnostics remain outside source commits in the local verification record.

## Scope and limits

This proves a clean local installation and login-page availability. It does not test account login, course editing, upgrades, existing-site migration, image publication or adoption by another service. It does not install a CA into host trust stores. Chromium and WebKit retain their lab HTTPS exception; Firefox and the CLI perform certificate validation with the captured run-local CA.
