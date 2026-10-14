# Verification evidence — 2026-10-14

Adds a run-owned Compose verification path for a clean Moodle installation. It preflights cached images and disk before build, disables build networking, binds allocated ports to loopback, caps app at 1 CPU/1 GiB and MariaDB at 1 CPU/512 MiB, checks the login DOM/theme/database, and removes only its Compose project.

## Recorded checks

`make verify-dry-run` and `make verify-test` passed. `make verify` stopped before build or container start because `dunglas/frankenphp:php8.4-bookworm` was not cached; no image pull occurred. The live Moodle/browser path remains unproven. Final verify-kit 1.2.1 contract validation is pending root’s final check.

## Scope and limits

Does not test account login, course editing, upgrades, or an existing Moodle database. Playwright environment setup is also pending; the required project lock is not updated.

## Current validation status

The project-local shared verify-kit files were refreshed to version 1.2.1. Root’s final serialized contract check is pending; treat the earlier project run above as evidence for the recorded source state, not as a claim that the latest vendor refresh has already been revalidated.
