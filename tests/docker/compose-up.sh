#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# shellcheck source=tests/docker/lib.sh
source "${SCRIPT_DIR}/lib.sh"
# shellcheck source=docker/tls-preflight.sh
source "${PROJECT_ROOT}/docker/tls-preflight.sh"

docker_require
docker_require_tools python3 curl openssl

cd "${PROJECT_ROOT}"

APP_BIND_HOST="${APP_BIND_HOST:-127.0.0.1}"
SITE_HOST="${MOODLE_HOST:-moodle.docker.test.127.0.0.1.sslip.io}"
EXISTING_HTTP_PORT=""
EXISTING_HTTPS_PORT=""

if [[ -n "$(docker compose ps -q --status running app 2>/dev/null || true)" ]]; then
  EXISTING_HTTP_PORT="$(docker_published_host_port "$(docker compose port app 80 2>/dev/null || true)" || true)"
  EXISTING_HTTPS_PORT="$(docker_published_host_port "$(docker compose port app 443 2>/dev/null || true)" || true)"
fi

if [[ -n "${EXISTING_HTTP_PORT}" ]]; then
  APP_HTTP_PORT="${EXISTING_HTTP_PORT}"
else
  APP_HTTP_PORT="$(docker_allocate_host_port "${APP_BIND_HOST}" "${APP_HTTP_PORT:-80}")"
fi

if [[ -n "${EXISTING_HTTPS_PORT}" ]]; then
  APP_HTTPS_PORT="${EXISTING_HTTPS_PORT}"
else
  APP_HTTPS_PORT="$(docker_allocate_host_port "${APP_BIND_HOST}" "${APP_HTTPS_PORT:-443}" "${APP_HTTP_PORT}")"
fi

export APP_BIND_HOST APP_HTTP_PORT APP_HTTPS_PORT

if [[ "${APP_HTTPS_PORT}" == "443" ]]; then
  SITE_URL="https://${SITE_HOST}"
else
  SITE_URL="https://${SITE_HOST}:${APP_HTTPS_PORT}"
fi

docker compose up -d --build

echo "Waiting for ${SITE_URL} ..."
tls_preflight_wait_for_https "${SITE_URL}"

if ! tls_preflight_check_url "${SITE_URL}"; then
  echo "TLS preflight failed; recreating the app container so expired Caddy certificates can be pruned." >&2
  docker compose up -d --no-deps --force-recreate app
  tls_preflight_wait_for_https "${SITE_URL}"
  tls_preflight_check_url "${SITE_URL}"
fi

echo "Publishing Moodle on ${SITE_URL}"
if [[ "${APP_HTTPS_PORT}" != "443" ]]; then
  echo "Port 443 is not this stack; https://${SITE_HOST} will hit whatever already owns ${APP_BIND_HOST}:443." >&2
fi
