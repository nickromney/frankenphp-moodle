#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:?usage: preflight.sh PROJECT_ROOT BROWSER_CACHE}"
BROWSER_CACHE="${2:?usage: preflight.sh PROJECT_ROOT BROWSER_CACHE}"
DOCKER_CMD="${DOCKER_CMD:-docker}"
MIN_FREE_KIB=26214400
PLAYWRIGHT_PYTHON="${VERIFY_PLAYWRIGHT_PYTHON:-$ROOT/.venv/bin/python}"

for tool in awk curl df grep python3; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "FAIL: required local tool is missing: $tool" >&2
    exit 1
  fi
done
if ! command -v "$DOCKER_CMD" >/dev/null 2>&1; then
  echo "FAIL: Docker CLI is unavailable" >&2
  exit 1
fi
if ! "$DOCKER_CMD" info >/dev/null 2>&1; then
  echo "FAIL: Docker daemon is unavailable" >&2
  exit 1
fi
if ! "$DOCKER_CMD" compose version >/dev/null 2>&1; then
  echo "FAIL: Docker Compose is unavailable" >&2
  exit 1
fi

available_kib="$(df -Pk "$ROOT" | awk 'END { print $4 }')"
case "$available_kib" in
  ''|*[!0-9]*) echo "FAIL: could not read available disk space for $ROOT" >&2; exit 1 ;;
esac
if [ "$available_kib" -lt "$MIN_FREE_KIB" ]; then
  echo "FAIL: $ROOT has $available_kib KiB free; at least $MIN_FREE_KIB KiB is required" >&2
  exit 1
fi

for image in \
  "${FRANKENPHP_IMAGE:-dunglas/frankenphp:php8.4-bookworm}" \
  "${DB_IMAGE:-mariadb:11.8}" \
  "composer:2"; do
  if ! "$DOCKER_CMD" image inspect "$image" >/dev/null 2>&1; then
    echo "FAIL: required image is not cached: $image; verification never pulls images" >&2
    exit 1
  fi
done

for required in Dockerfile compose.yml docker/Caddyfile docker/entrypoint.sh verify-moodle.sh; do
  if [ ! -f "$ROOT/$required" ]; then
    echo "FAIL: required app input is missing: $ROOT/$required" >&2
    exit 1
  fi
done

if [ ! -x "$PLAYWRIGHT_PYTHON" ]; then
  echo "FAIL: pinned Playwright interpreter missing: $PLAYWRIGHT_PYTHON; prepare the locked verification environment before launch" >&2
  exit 1
fi
if [ ! -d "$BROWSER_CACHE" ]; then
  echo "FAIL: shared Playwright browser cache is missing: $BROWSER_CACHE" >&2
  exit 1
fi
"$PLAYWRIGHT_PYTHON" - "$BROWSER_CACHE" <<'PY'
import importlib.metadata
import json
import pathlib
import sys

cache = pathlib.Path(sys.argv[1])
expected = "1.63.0"
try:
    actual = importlib.metadata.version("playwright")
except importlib.metadata.PackageNotFoundError:
    print("FAIL: pinned Playwright package is not installed", file=sys.stderr)
    raise SystemExit(1)
if actual != expected:
    print(f"FAIL: Playwright is {actual}; verification requires {expected}", file=sys.stderr)
    raise SystemExit(1)
package = pathlib.Path(importlib.metadata.distribution("playwright").locate_file("playwright"))
manifest_path = package / "driver" / "package" / "browsers.json"
if not manifest_path.is_file():
    print(f"FAIL: Playwright browser manifest missing: {manifest_path}", file=sys.stderr)
    raise SystemExit(1)
manifest = json.loads(manifest_path.read_text())
for name in ("chromium", "firefox", "webkit"):
    item = next((entry for entry in manifest["browsers"] if entry["name"] == name), None)
    revision = item["revision"] if item else "unknown"
    if item is None or not (cache / f"{name}-{revision}").is_dir():
        print(f"FAIL: Playwright {expected} {name} revision {revision} missing from {cache}", file=sys.stderr)
        raise SystemExit(1)
print(f"OK: Playwright {actual} and Chromium, Firefox, WebKit cache are ready")
PY

echo "OK: Docker Compose, 25 GiB free-space floor, cached build/runtime images, and browser runtime are ready"

