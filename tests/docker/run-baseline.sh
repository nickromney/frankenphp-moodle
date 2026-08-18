#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# shellcheck source=tests/docker/lib.sh
source "${SCRIPT_DIR}/lib.sh"

RESULTS_DIR=""
KEEP_RESOURCES=false
REBUILD_IMAGE=false
APP_HTTP_PORT="${APP_HTTP_PORT:-18080}"
APP_HTTPS_PORT="${APP_HTTPS_PORT:-18443}"
APP_BIND_HOST="${APP_BIND_HOST:-127.0.0.1}"
SITE_HOST="${MOODLE_HOST:-moodle.docker.test.127.0.0.1.sslip.io}"

DB_IMAGE="mariadb:11.8"
ROOT_PASSWORD="rootpass"
DB_NAME="moodle"
DB_USER="moodle"
DB_PASSWORD="moodlepass"
ADMIN_PASSWORD="Adminpass123!"
ADMIN_EMAIL="demo@moodle.test"
COMPOSE_PROJECT_NAME="${COMPOSE_PROJECT_NAME:-frankenphpmoodlebaseline}"

function site_url() {
  if [[ "${APP_HTTPS_PORT}" == "443" ]]; then
    printf 'https://%s\n' "${SITE_HOST}"
  else
    printf 'https://%s:%s\n' "${SITE_HOST}" "${APP_HTTPS_PORT}"
  fi
}

SITE_URL="$(site_url)"

function usage() {
  cat <<EOF
Build, install, and verify the FrankenPHP Moodle baseline via Docker Compose.

Usage:
  tests/docker/run-baseline.sh [options]

Options:
  --results-dir DIR     Write logs and results to DIR
  --keep-resources      Keep containers and volumes after the run
  --rebuild-image       Force a clean Docker rebuild
  --http-port PORT      Publish container port 80 on PORT (default: ${APP_HTTP_PORT})
  --https-port PORT     Publish container port 443 on PORT (default: ${APP_HTTPS_PORT})
  -h, --help            Show this help text
EOF
}

function compose() {
  APP_HTTP_PORT="${APP_HTTP_PORT}" \
  APP_HTTPS_PORT="${APP_HTTPS_PORT}" \
  APP_BIND_HOST="${APP_BIND_HOST}" \
  DB_IMAGE="${DB_IMAGE}" \
  MOODLE_DB_ROOT_PASSWORD="${ROOT_PASSWORD}" \
  MOODLE_DB_NAME="${DB_NAME}" \
  MOODLE_DB_USER="${DB_USER}" \
  MOODLE_DB_PASSWORD="${DB_PASSWORD}" \
  MOODLE_HOST="${SITE_HOST}" \
  MOODLE_ADMIN_PASSWORD="${ADMIN_PASSWORD}" \
  MOODLE_ADMIN_EMAIL="${ADMIN_EMAIL}" \
  COMPOSE_PROJECT_NAME="${COMPOSE_PROJECT_NAME}" \
  "${DOCKER_CMD}" compose -f "${PROJECT_ROOT}/compose.yml" "$@"
}

function cleanup_resources() {
  if [[ "${KEEP_RESOURCES}" == "true" ]]; then
    return 0
  fi

  compose down -v --remove-orphans >/dev/null 2>&1 || true
}

function wait_for_http() {
  local attempts=90
  while (( attempts > 0 )); do
    if curl -kfsSL -o /dev/null "${SITE_URL}" >/dev/null 2>&1; then
      return 0
    fi
    attempts=$((attempts - 1))
    sleep 1
  done

  echo "Error: FrankenPHP did not start serving ${SITE_URL} in time." >&2
  return 1
}

function assert_asset_url_serves_ok() {
  local label="$1"
  local asset_url="$2"

  if [[ -z "${asset_url}" ]]; then
    echo "Error: could not determine ${label} asset URL from ${SITE_URL}." >&2
    return 1
  fi

  if ! curl -kfsSL -o /dev/null "${asset_url}" >/dev/null 2>&1; then
    echo "Error: ${label} asset did not load successfully: ${asset_url}" >&2
    return 1
  fi
}

function assert_theme_styles_the_page() {
  local asset_url="$1"
  local expected_theme="${MOODLE_THEME:-lovely}"

  if [[ "${asset_url}" != *"/theme/styles.php/${expected_theme}/"* ]]; then
    echo "Error: expected the page to be styled by theme '${expected_theme}', got stylesheet URL: ${asset_url}" >&2
    return 1
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --results-dir)
      RESULTS_DIR="${2:?missing value for --results-dir}"
      shift 2
      ;;
    --keep-resources)
      KEEP_RESOURCES=true
      shift
      ;;
    --rebuild-image)
      REBUILD_IMAGE=true
      shift
      ;;
    --http-port)
      APP_HTTP_PORT="${2:?missing value for --http-port}"
      SITE_URL="$(site_url)"
      shift 2
      ;;
    --https-port)
      APP_HTTPS_PORT="${2:?missing value for --https-port}"
      SITE_URL="$(site_url)"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Error: unknown option '$1'." >&2
      usage >&2
      exit 1
      ;;
  esac
done

# shellcheck source=docker/tls-preflight.sh
source "${PROJECT_ROOT}/docker/tls-preflight.sh"

docker_require
docker_require_tools awk curl date mktemp sed python3 openssl

APP_HTTP_PORT="$(docker_allocate_host_port "${APP_BIND_HOST}" "${APP_HTTP_PORT}")"
APP_HTTPS_PORT="$(docker_allocate_host_port "${APP_BIND_HOST}" "${APP_HTTPS_PORT}" "${APP_HTTP_PORT}")"
SITE_URL="$(site_url)"

if [[ -z "${RESULTS_DIR}" ]]; then
  RESULTS_DIR="$(mktemp -d "/tmp/frankenphp-moodle-$(date +%Y%m%d-%H%M%S)-XXXX")"
else
  mkdir -p "${RESULTS_DIR}"
fi

trap cleanup_resources EXIT

RESULTS_TSV="${RESULTS_DIR}/results.tsv"
printf 'status\turl\ttable_count\tartifacts\n' >"${RESULTS_TSV}"

BUILD_LOG="${RESULTS_DIR}/build.log"
DB_LOG="${RESULTS_DIR}/db.log"
APP_LOG="${RESULTS_DIR}/app.log"
DB_SETUP_LOG="${RESULTS_DIR}/database_setup.txt"
PHP_SETTINGS_LOG="${RESULTS_DIR}/php_settings.txt"
VERIFY_LOG="${RESULTS_DIR}/verify.log"
status="FAIL"
table_count="0"

compose down -v --remove-orphans >/dev/null 2>&1 || true

if [[ "${REBUILD_IMAGE}" == "true" ]]; then
  compose build --no-cache 2>&1 | tee "${BUILD_LOG}"
else
  compose build 2>&1 | tee "${BUILD_LOG}"
fi

compose up -d

wait_for_http
tls_preflight_check_url "${SITE_URL}"

compose exec -T app sh -lc \
  "php -i | sed -n '/^max_input_vars =>/p;/^memory_limit =>/p'" | tee "${PHP_SETTINGS_LOG}"

compose exec -T app sh -lc \
  "! test -L /app/public/config.php"

theme_asset_url="$(
  curl -kfsSL "${SITE_URL}" | grep -oE 'https://[^" ]+/theme/styles\.php[^" ]+' | head -n 1
)"

javascript_asset_url="$(
  curl -kfsSL "${SITE_URL}" | grep -oE 'https://[^" ]+/lib/javascript\.php[^" ]+' | head -n 1
)"

assert_asset_url_serves_ok "theme stylesheet" "${theme_asset_url}"
assert_theme_styles_the_page "${theme_asset_url}"
assert_asset_url_serves_ok "javascript bundle" "${javascript_asset_url}"

compose exec -T db sh -lc \
  "mariadb -uroot -p${ROOT_PASSWORD} -Nse \"SHOW CREATE DATABASE ${DB_NAME};\"" | tee "${DB_SETUP_LOG}"

table_count="$(
  compose exec -T db sh -lc \
    "mariadb -u${DB_USER} -p${DB_PASSWORD} ${DB_NAME} -Nse \"SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = '${DB_NAME}' AND table_name LIKE 'mdl_%';\""
)"

if "${PROJECT_ROOT}/verify-moodle.sh" \
  --backend frankenphp \
  --database mariadb \
  --skip-php-check \
  --url "${SITE_URL}" \
  -k \
  --config-check-command "docker compose -p ${COMPOSE_PROJECT_NAME} -f ${PROJECT_ROOT}/compose.yml exec -T app test -f /app/public/config.php" \
  --web-check-command "docker compose -p ${COMPOSE_PROJECT_NAME} -f ${PROJECT_ROOT}/compose.yml exec -T app sh -lc \"grep -aEq 'frankenphp|caddy' /proc/1/cmdline\"" \
  --db-ping-command "docker compose -p ${COMPOSE_PROJECT_NAME} -f ${PROJECT_ROOT}/compose.yml exec -T db mariadb-admin ping -h127.0.0.1 -uroot -p${ROOT_PASSWORD}" \
  --db-query-command "docker compose -p ${COMPOSE_PROJECT_NAME} -f ${PROJECT_ROOT}/compose.yml exec -T db mariadb -u${DB_USER} -p${DB_PASSWORD} ${DB_NAME} -Nse \"SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = '${DB_NAME}' AND table_name LIKE 'mdl_%';\"" \
  --table-min 400 \
  --content-match "Moodle" 2>&1 | tee "${VERIFY_LOG}"; then
  status="PASS"
fi

compose restart app >/dev/null
wait_for_http
tls_preflight_check_url "${SITE_URL}"

compose exec -T app sh -lc \
  "! test -L /app/public/config.php"

assert_asset_url_serves_ok "theme stylesheet" "${theme_asset_url}"
assert_theme_styles_the_page "${theme_asset_url}"
assert_asset_url_serves_ok "javascript bundle" "${javascript_asset_url}"

if ! "${PROJECT_ROOT}/verify-moodle.sh" \
  --backend frankenphp \
  --database mariadb \
  --skip-php-check \
  --url "${SITE_URL}" \
  -k \
  --config-check-command "docker compose -p ${COMPOSE_PROJECT_NAME} -f ${PROJECT_ROOT}/compose.yml exec -T app test -f /app/public/config.php" \
  --web-check-command "docker compose -p ${COMPOSE_PROJECT_NAME} -f ${PROJECT_ROOT}/compose.yml exec -T app sh -lc \"grep -aEq 'frankenphp|caddy' /proc/1/cmdline\"" \
  --db-ping-command "docker compose -p ${COMPOSE_PROJECT_NAME} -f ${PROJECT_ROOT}/compose.yml exec -T db mariadb-admin ping -h127.0.0.1 -uroot -p${ROOT_PASSWORD}" \
  --db-query-command "docker compose -p ${COMPOSE_PROJECT_NAME} -f ${PROJECT_ROOT}/compose.yml exec -T db mariadb -u${DB_USER} -p${DB_PASSWORD} ${DB_NAME} -Nse \"SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = '${DB_NAME}' AND table_name LIKE 'mdl_%';\"" \
  --table-min 400 \
  --content-match "Moodle" >/dev/null 2>&1; then
  status="FAIL"
fi

compose logs db >"${DB_LOG}" 2>&1 || true
compose logs app >"${APP_LOG}" 2>&1 || true

printf '%s\t%s\t%s\t%s\n' "${status}" "${SITE_URL}" "${table_count}" "${RESULTS_DIR}" >>"${RESULTS_TSV}"

cat "${RESULTS_TSV}"

if [[ "${status}" != "PASS" ]]; then
  echo "FrankenPHP baseline failed. Artifacts: ${RESULTS_DIR}" >&2
  exit 1
fi

echo "FrankenPHP baseline passed. Artifacts: ${RESULTS_DIR}"
