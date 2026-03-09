#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
DOCKER_CMD="${DOCKER_CMD:-docker}"
SERVICE_NAME="${SERVICE_NAME:-app}"
CONTAINER_CA_PATH="${CONTAINER_CA_PATH:-}"

function fail() {
  printf 'Error: %s\n' "$1" >&2
  exit 1
}

function require_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "required command not found: $1"
}

require_cmd "${DOCKER_CMD}"
require_cmd mktemp

"${DOCKER_CMD}" info >/dev/null 2>&1 || fail "cannot talk to the Docker daemon"

function detect_container_ca_path() {
  local attempts=30
  local path=""

  while (( attempts > 0 )); do
    path="$("${DOCKER_CMD}" compose -f "${PROJECT_ROOT}/compose.yml" exec -T "${SERVICE_NAME}" \
      sh -lc 'find /data /config -path "*/authorities/local/root.crt" -print 2>/dev/null | head -n 1' \
      2>/dev/null || true)"

    if [[ -n "${path}" ]]; then
      printf '%s\n' "${path}"
      return 0
    fi

    attempts=$((attempts - 1))
    sleep 1
  done

  fail "could not locate Caddy local root CA; wait for the app to finish booting and serving HTTPS"
}

if [[ -z "${CONTAINER_CA_PATH}" ]]; then
  CONTAINER_CA_PATH="$(detect_container_ca_path)"
fi

tmp_cert="$(mktemp "${TMPDIR:-/tmp}/frankenphp-moodle-root-XXXX.crt")"
cleanup() {
  rm -f "${tmp_cert}"
}
trap cleanup EXIT

"${DOCKER_CMD}" compose -f "${PROJECT_ROOT}/compose.yml" cp \
  "${SERVICE_NAME}:${CONTAINER_CA_PATH}" "${tmp_cert}" >/dev/null

case "$(uname -s)" in
  Darwin)
    require_cmd security
    printf 'Installing Caddy local root CA into the macOS System keychain.\n'
    sudo security add-trusted-cert -d -r trustRoot \
      -k /Library/Keychains/System.keychain "${tmp_cert}"
    ;;
  Linux)
    if command -v update-ca-certificates >/dev/null 2>&1; then
      printf 'Installing Caddy local root CA into the Linux system trust store.\n'
      sudo cp "${tmp_cert}" /usr/local/share/ca-certificates/frankenphp-moodle-local.crt
      sudo update-ca-certificates
    else
      fail "unsupported Linux trust store tooling; install ${tmp_cert} manually"
    fi
    ;;
  *)
    fail "unsupported platform $(uname -s); install ${tmp_cert} manually"
    ;;
esac

printf 'Local CA installed. You may still need to import the certificate into browser-specific stores.\n'
