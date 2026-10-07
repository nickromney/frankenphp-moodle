# Moodle estate: what each repository does, and where they should converge

Written 2026-10-06, when Moodle 5.3.0 (the next LTS) and 5.2.4 were released.

## The five repositories

| Repository | What it is | Topology | Status |
| --- | --- | --- | --- |
| `server-manager` | Rails control plane (with a Laravel parity slice) that turns desired server/site state into Ansible runs over SSH; SpinupWP-like API; adopts existing SpinupWP servers | Direct PHP (nginx + PHP-FPM pool per site) **and** container runtime (Compose: FrankenPHP Moodle + cron + MariaDB/PostgreSQL + Redis) | Most complete. The production target in OSA's August proposal. |
| `frankenphp-moodle` | One FrankenPHP image + Compose stack that installs and verifies Moodle; ships the `lovely` theme | Container | Most advanced container runtime. `server-manager` carries a vendored copy of its Dockerfile, Caddyfile and entrypoint. |
| `laemp` | `laemp.sh`, a single Bash installer for LAMP/LEMP + Moodle on Ubuntu/Debian, with Docker, Lima and Slicer test platforms | Direct PHP on one host | Restructured fork of `amp-moodle` (March 2026). |
| `amp-moodle` | The original `laemp.sh` repo (2021), plus an Ansible container-verify path and the first FrankenPHP spike | Direct PHP on one host | Still receives the same changes as `laemp`; `laemp.sh` has drifted by about 250 lines. |
| `OSA` (work) | Production estate for Online Safety Alliance: Terraform/OpenTofu (London migration, Aurora), operational runbooks, and `current/` mirrors of live nginx/PHP-FPM config | Production EC2 + Aurora MySQL, Moodle **4.4.2**, PHP 8.3 | Source of production truth; consumes the others. |

How they relate:

```text
OSA (production requirements, Aurora, runbooks)
  └─> server-manager  ── direct PHP ──> Ansible moodle role  (same contract laemp.sh proves on one host)
                      └─ containers ──> vendored frankenphp-moodle build files
laemp / amp-moodle  ── one-host installer and VM/container test bed for the direct-PHP contract
```

## How they differ

| | server-manager | frankenphp-moodle | laemp / amp-moodle | OSA production |
| --- | --- | --- | --- | --- |
| Version input | `app_version` "5.2.4" → release code `5024` | `MOODLE_VERSION=5.2.4` | `-m 5024` | 4.4.2 |
| Moodle source | Git tag (peeled-commit check), archive fallback | Release package | Release package | Git checkout |
| PHP | 8.3-8.4 (distro packages) | 8.4 (FrankenPHP) | 8.1-8.4 by Moodle family | 8.3 FPM, pools per site |
| Database | MariaDB, PostgreSQL, external (Aurora) | MariaDB 11.8 container only | MariaDB (distro), PostgreSQL (PGDG) | Aurora MySQL 8.0 |
| Web server | nginx | Caddy (FrankenPHP) | nginx or Apache | nginx |
| Cron | cron entry / `moodle-cron` container | **none** | cron | cron |
| X-Accel-Redirect, MDL-69333 deny rules | yes | **no** | yes | yes |
| Cache/session | Redis (containers), Memcached option | none | Memcached option | — |
| Verification | `verify.yml` (service, DB floors, HTTPS, CLI) | `verify-moodle.sh` + BATS + baseline | BATS + Playwright + platform matrices | Manual runbooks |

## What changed for 5.2.4 and 5.3.0

The shared release contract, now implemented in all four code repositories:

| Release | Tag commit | Package | sha256 | PHP | MariaDB | PostgreSQL |
| --- | --- | --- | --- | --- | --- | --- |
| 5.2.4 (default) | `2df605b1e093` | `stable502/moodle-5.2.4.tgz` | `8569b63f…73cf` | 8.3-8.4 | 10.11+ | 16+ |
| 5.3.0 | `42622298fe06` | `stable503/moodle-5.3.tgz` | `7e5edf11…d511` | 8.3-8.4 | **11.4+** | **17+** |

Facts checked against the published packages and tags, not documentation:

- `moodle-X.Y.Z.tgz` is the tagged release. The weekly build is `moodle-latest-NNN.tgz`, and on release day `moodle-latest-502.tgz` was still `5.2.3+`. `frankenphp-moodle`'s README claimed otherwise.
- The first release of a major version has no patch digit: `moodle-5.3.tgz`. `moodle-5.3.0.tgz` and (on release day) `moodle-latest-503.tgz` return 404.
- `download.moodle.org` returned 502 on release day while `packaging.moodle.org` served the same files. Every repo now falls back to it.
- `server-manager`'s archive strategy built `moodle-latest-5021.tgz`, which never existed. That path was broken for every 5.x patch release.

Per repository:

- **frankenphp-moodle**: `docker/fetch-moodle.sh` (series derivation, X.Y.0 naming, mirror fallback, pinned checksums), default 5.2.4, `MOODLE_VERSION=5.3.0` supported. The `lovely` theme now declares `[502, 503]`. It also loads Bootstrap's Carousel from whichever module the branch ships: 5.3 replaced `theme_boost/bootstrap/*` with a core `bootstrap` bundle (MDL-88766), which broke the hero pause control and the login video. The theme renders course-index controls in both the 5.2 and 5.3 drawer blocks (MDL-89050).
- **laemp / amp-moodle** (identical `laemp.sh` patch): default `5024`, `5030` supported, pinned checksums, mirror fallback, PHP 8.3-8.4 for 5.3. A MariaDB preflight stops before provisioning if the host would run MariaDB < 11.4 for 5.3. PostgreSQL 17 is installed for 5.3. Docker matrices gained 5.3 rows on Debian 13.
- **server-manager**: default 5.2.4 from one constant (`Moodle::Version::DEFAULT_VERSION`), commit pins for 5.2.4 and 5.3.0, the archive-name fix, mirror fallback, checksum assert, and release-aware DB floors in the role, `verify.yml` and the Moodle profile (`postgresql_version` 17 for 5.3). The local MariaDB preflight and the vendored Dockerfile are synced to `fetch-moodle.sh`.

## 5.3 LTS: what to plan for

Mindfield's [5.3 LTS upgrade article](https://mindfieldconsulting.com/moodle-5-3-lts-upgrade/) is right on strategy and wrong on two facts:

- **Strategy (agree)**: 5.3 is the LTS (security support to 2029-10-01; 5.2 and 4.5 end 2027-10-04). Target a *tested point release*, rehearse on a copy of real data, and capture before/after numbers (completions, grades, enrolments, key reports), not just a login check. Plan for silent failures in scheduled tasks, mail and integrations. 5.2.2 was a "do not upgrade" release because grade penalties were applied twice, and it was the default in every repo here until today.
- **Database floors (article wrong)**: it lists MariaDB 10.11 / PostgreSQL 16 for 5.3. The `v5.3.0` `admin/environment.xml` requires **MariaDB 11.4 and PostgreSQL 17**. Ubuntu 24.04 and Debian 12 ship MariaDB 10.11, so distro MariaDB cannot run 5.3. Aurora MySQL 8.0 and MySQL 8.4 are unchanged.
- **Upgrade path (article stricter than Moodle)**: it says upgrade from 4.5; the 5.3 environment file says `requires="4.4"`, so OSA's 4.4.2 can go directly to 5.3. Moodle 4.4 is out of security support, so OSA is exposed until it moves.
- **Classic theme**: removed in 5.3 (present in 5.2.4). Presets and block positions do not migrate.

OSA-specific risks, from its own plugin inventory (`documentation/2024-04-11-2024-04-11-plugins.md`): `mod_chat`, `mod_survey`, `auth_cas` and `mlbackend_php` are all removed since 5.0. A stored analytics setting that still points at `mlbackend_php` can stop the upgrade, which is the article's opening example. These need an inventory and a decision before any rehearsal: replace, retire, or install the separately maintained plugin.

Default stays 5.2.4 until a 5.3.x point release has been rehearsed against a copy of OSA data; then move the default in one change across all four repos.

## Harmonisation opportunities, in priority order

1. **Retire one of `laemp` / `amp-moodle`.** They are the same product, and every change is currently made twice. `laemp` has the cleaner layout (platforms/docker, lima, slicervm); `amp-moodle` holds the Ansible container-verify path and the FrankenPHP spike, both of which `server-manager` and `frankenphp-moodle` now supersede. Archive `amp-moodle` after moving anything still unique.
2. **One release manifest.** The same version, commit and sha256 table now lives in four places: `fetch-moodle.sh`, `laemp.sh`, the Ansible role defaults and the Rails constant. Make `frankenphp-moodle`'s table (or a small `moodle-releases.json`) the source, and have the others read or test against it, so the next bump is one edit plus CI.
3. **Done (2026-10-06): server-manager no longer copies frankenphp-moodle.** `make publish` here builds amd64 and arm64 images and pushes them to the loopback registry Server Manager's Kamal deploys use (`localhost:5555`, run by `bin/local-registry` with a named volume and a digest-pinned `registry:3.1.2`). Server Manager references `localhost:5555/frankenphp-moodle:<version>`, rewrites the legacy `server-manager/frankenphp-moodle` name so nothing is pulled from Docker Hub, and opens an SSH reverse forward to the registry for each playbook run, as Kamal does. The image gained a behind-proxy mode (`MOODLE_TLS_MODE=off`, `MOODLE_SSLPROXY=true`), and Server Manager sites keep Boost (`MOODLE_THEME=boost`). The copied templates, which wrote `config.php` world-readable, are deleted. Remaining gap: the registry must be on the machine that runs the playbooks.
4. **Bring frankenphp-moodle up to the production contract** that OSA and server-manager already encode:
   - a cron service or loop (server-manager's `moodle-cron` exists; the standalone compose has none);
   - MDL-69333 deny rules in the Caddyfile (`admin/environment.xml`, `db/install.xml`, readmes and `upgrade.txt` are reachable under `public/`);
   - X-Accel-Redirect-equivalent file serving;
   - PostgreSQL as a compose option;
   - optional Redis.
5. **Moodle router (`r.php`).** No repo configures Moodle 5.x routing, which the 5.3 environment check reports as an optional warning (`check_router_configuration`). Add it to the nginx role, `laemp.sh` and the Caddyfile together.
6. **Shared upgrade preflight.** Encode the 5.3 upgrade risks as checks: removed plugins still installed, `mlbackend_php` configured, Classic theme in use, DB floor. Put them in `verify-moodle.sh` (or a sibling), call it from `server-manager`'s `verify.yml`, and run it against a restored OSA copy.
7. **Version vocabulary.** `server-manager` takes "5.2.4" and converts to `5024`; `laemp.sh` takes `5024` only, and its code cannot express patch ≥ 10; `frankenphp-moodle` takes "5.2.4". Accept dotted versions everywhere and keep the code as an internal detail.

## Verification on 2026-10-06

- `frankenphp-moodle` Docker baseline (build, install, `verify-moodle.sh`, TLS preflight), both against MariaDB 11.4, the 5.3 minimum:
  - **5.2.4: PASS, 490 tables.**
  - **5.3.0: PASS, 499 tables.**
  - Both builds verified the pinned package checksums.
  - A first 5.3 install took longer than the runner's old 90-second HTTP wait. The wait is now `BASELINE_HTTP_WAIT_SECONDS` (default 240).
- `lovely` theme in Chromium on both releases:
  - The two-slide hero renders.
  - The pause control sets `aria-pressed`, and the carousel stays paused past its interval.
  - No console errors.
  - Light and dark mode were both checked on 5.3.
- The screenshots found two more 5.3 theme regressions, now fixed:
  - Boost 5.3 paints `.main-inner` with `var(--bs-body-bg)`, so lovely's white content column merged into its sand canvas.
  - The navbar edit switch is now the design-system `mds-switch`, whose "Edit mode" label was dark serif on the dark navbar.
- Since Moodle 5.2, **new installs have the site home disabled** (`enablemyhome` = 0; upgraded sites keep it on). On a fresh install `/` sends visitors to the login page or the dashboard, so lovely's hero is hidden until an admin enables the site home. Decide whether the entrypoint should set it when `MOODLE_THEME=lovely`.
- `laemp.sh`:
  - Release helpers are unit-tested in both forks.
  - On macOS with a stubbed distro, the dry-run behaves exactly as on `main` for every existing case, and rejects PHP 8.2 and 8.5 for 5.3.
  - The `-m` dry-run BATS cases fail identically on `main` when PHP is not installed, so they need the prereqs image.
  - **A real 5.3 install through `laemp.sh` (Debian 13 MariaDB, PostgreSQL 17 via PGDG) has not been run yet.**
- `server-manager`:
  - Role defaults render correctly for 5024, 5030, 4042, 503 and 5021.
  - Both playbooks pass the syntax check.
  - The full Rails suite: 3580 runs, 2 failures. Both fail identically on `main`: they expect a SpinupWP adoption error message that changed when WordPress adoption landed.
- Published `localhost:5555/frankenphp-moodle:5.2.4` (`sha256:9e43b5b5…`) and `:5.3.0` (`sha256:d2b51776…`), each for amd64 and arm64, from a working tree with uncommitted changes, so the immutable tags carry `-dirty`. Republish after committing.
- End to end on a disposable Lima VM (Ubuntu, rootful Docker): Server Manager's `runtime_compose` role, with vars generated by its own `RuntimeComposePlan` from the legacy image name, ran over an inventory carrying the `-R` forward.
  - Without the forward the VM gets `Connection refused` from `127.0.0.1:5555`; with it, HTTP 200.
  - The role pulled the published digest (arm64), and `compose up --wait` reported MariaDB, Moodle 5.3.0 and cron healthy in 109 seconds.
  - Through an nginx TLS front configured like Server Manager's, the login page returned 200 with every link on `https://`.
  - `config.php` was mode 600 with `$CFG->sslproxy = true;`, the theme was Boost, and cron ran tasks.
  - A second role run and a container restart left exactly one `sslproxy` line.
- Docker store damage: the disk filled during the first baseline run, and Docker Desktop's containerd store kept a truncated unpacked layer of `mariadb:11.8` (a 0-byte entrypoint). It survives `docker rmi`, re-pull and restart. Testing used `mariadb:11.4`; `compose.yml` still defaults to `mariadb:11.8`, which will not start on this machine until the store is repaired.

## Agent operation and plan status

For the current ownership, action-effect and evidence contracts, use [the operating model](agent-system.md). Its implemented plan covers agent navigation and documentation. Feature proposals below remain proposals until their own acceptance evidence is recorded; dated observations retain their original scope.

## Image-to-operator handoff and reset boundary

| Artifact / action | Owner | Acceptance |
| --- | --- | --- |
| Desired PHP/Moodle/container shape | Root `Dockerfile`, `compose.yml` | Baseline tuple and persistent volume layout reviewed |
| Runtime result | `verify-moodle.sh`; `make baseline` | Independent database/application/TLS checks against the named compose project |
| Published image | `scripts/publish-image.sh`; `make publish` | Digest, architecture and registry identity retained; image publication is an effect |
| Server Manager consumption | Explicit image/digest in the receiving site's configuration | Separate adoption/provisioning and endpoint verification; publishing alone proves neither |
| Theme | `theme/lovely/` | Separate browser/interaction acceptance from installer health |

Retain source revision, image digest, compose project, volume identity, endpoint
and dated verifier result. `make down` removes compose volumes; choose an explicit
retention/reset decision before it. Offline `make test` and `make test-preflight`
prove smoke/TLS preflight fixtures only. Runtime/build/publish checks require an
attended available container environment and are not part of local fixture proof.
