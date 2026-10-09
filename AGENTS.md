# frankenphp-moodle agent guide

## Verify

- Default suite: `make test` (BATS smoke). `make test-preflight` runs the TLS preflight BATS. Pre-push gate: `lefthook run pre-push --force`, which runs `uv run --locked make test` and `test_verify_http.py`.
- Offline tests prove smoke and TLS preflight fixtures only. Runtime checks need an attended container environment; `verify-moodle.sh` is the acceptance surface.
- `make baseline` builds, installs and starts containers and may download images. `make publish` pushes multiarch images to a loopback registry.
- `make down` removes compose volumes and is data-destructive; choose retention or reset first.
- Publishing creates a consumable image; Server Manager adoption is a separate step.
