#!/usr/bin/env bash

set -euo pipefail

DOCKER_CMD="${DOCKER_CMD:-docker}"

function docker_require() {
  if ! command -v "${DOCKER_CMD}" >/dev/null 2>&1; then
    echo "Error: ${DOCKER_CMD} is not installed or not in PATH." >&2
    exit 1
  fi

  if ! "${DOCKER_CMD}" info >/dev/null 2>&1; then
    echo "Error: cannot talk to the Docker daemon." >&2
    exit 1
  fi
}

function docker_require_tools() {
  local tool
  for tool in "$@"; do
    if ! command -v "${tool}" >/dev/null 2>&1; then
      echo "Error: required tool '${tool}' is not installed." >&2
      exit 1
    fi
  done
}
