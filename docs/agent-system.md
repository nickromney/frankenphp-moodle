# frankenphp-moodle: agent operating model

Adopted 6 October 2026 from local source and command inspection.
Container runtime/image for Moodle on FrankenPHP and MariaDB.

## Read by intent

Start with the local agent guide and build manifest. For domain or behavior
changes, follow the owners below, then the relevant contract/test. These
documents retain product detail and historical evidence:

- [README.md](../README.md)

## System ownership

| Owner | Responsibility |
| --- | --- |
| [Dockerfile](../Dockerfile) | Image/runtime contract and persistent service topology. |
| [compose.yml](../compose.yml) | Image/runtime contract and persistent service topology. |
| [verify-moodle.sh](../verify-moodle.sh) | Independent runtime acceptance checks. |
| [theme/lovely](../theme/lovely) | Theme source and design/feasibility evidence. |
| [docs](../docs) | Theme source and design/feasibility evidence. |

Intent selects the owning policy; that policy produces decisions or artifacts;
adapters perform effects; verification establishes the result. Change the
owner once and keep alternate surfaces on that same contract.

## Invariants

- Container runtime ownership differs from laemp host provisioning.
- make down removes volumes; it is data destructive.

## Existing action interfaces

These are inspected command surfaces, not a report that they ran. Read current
help and recipes for arguments, dependencies and lifecycle hooks before use.
Examples containing placeholder paths or bracketed options are grammar.

| Command | Effects and evidence |
| --- | --- |
| `make test` | Default smoke BATS suite. |
| `make test-preflight` | TLS preflight BATS. |
| `make baseline` | Build/install/verify runtime; starts containers and may download. |
| `make publish` | Pushes multiarch images to loopback registry; explicit publishing action. |

## Observe, verify and retain

Establish source revision, dirty state and relevant input identity before
choosing an action. Keep intended settings, cached artifacts and observed
runtime state distinct. An existing artifact is not a freshness or readiness
claim. Use the smallest deterministic fixture at the changed seam first;
expand to process, browser, device or deployment checks only when that
claim needs them. Record unavailable evidence explicitly.

Retain the command/configuration, source and input identity, result, limitation
and next discriminating check. Reuse evidence only while its relevant inputs
remain applicable. Promote a reproducible failure to a regression fixture,
a design decision to its owning document, and a repeated operator correction
to one concise guide rule. Keep private observations in private artifacts.

## Implemented plan for this pass

- [x] Map current source ownership and existing interfaces.
- [x] Make command effects and evidence limits discoverable.
- [x] Route agent work here and retain detailed product plans at their owners.

Acceptance: owner paths and document links resolve; current instructions
match inspected source; catalog hashes bind this context to the reviewed
bytes. This is documentation/control navigation acceptance. Product runtime
checks retain their own scope and are not certified by this pass.

## Project decisions

Use Dockerfile/compose.yml as desired runtime inputs and verify-moodle.sh as the acceptance surface. Capture Moodle/PHP/image identity, compose project, volume identity, endpoint and dated verifier outcome when claiming a working estate. A smoke BATS pass does not establish browser/TLS/database readiness. Keep theme behavior acceptance distinct from image/bootstrap acceptance. Publishing creates a consumable image; Server Manager adoption/provisioning remains a separate ownership boundary. Reuse the existing baseline to verify one changed concern at a time, and retain volumes unless the task explicitly calls for reset; make down removes them.
