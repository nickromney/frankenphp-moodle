#!/usr/bin/env bash
# Build the FrankenPHP Moodle image for amd64 and arm64 and push it to the
# loopback registry Server Manager deploys from (server-manager: bin/local-registry).
# Nothing is pushed to an external registry.
#
# Usage: scripts/publish-image.sh <moodle-version> [<moodle-version>...]
#
# Tags pushed for each version:
#   <registry>/frankenphp-moodle:<version>             the tag Server Manager deploys
#   <registry>/frankenphp-moodle:<version>-<revision>  immutable, for rollback and audit
#
# Environment:
#   PUBLISH_REGISTRY   default localhost:5555
#   PUBLISH_BUILDER    default kamal-local-registry-docker-container (Kamal's builder,
#                      which uses host networking so it can reach the loopback registry)
#   PUBLISH_PLATFORMS  default linux/amd64,linux/arm64
#   ALLOW_DIRTY=1      publish from a working tree with uncommitted changes

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REGISTRY="${PUBLISH_REGISTRY:-localhost:5555}"
BUILDER="${PUBLISH_BUILDER:-kamal-local-registry-docker-container}"
PLATFORMS="${PUBLISH_PLATFORMS:-linux/amd64,linux/arm64}"
REPOSITORY="${REGISTRY}/frankenphp-moodle"

function fail() {
  echo "publish-image: $*" >&2
  exit 1
}

[[ $# -gt 0 ]] || fail "usage: scripts/publish-image.sh <moodle-version> [<moodle-version>...]"

# shellcheck source=docker/fetch-moodle.sh
source "${PROJECT_ROOT}/docker/fetch-moodle.sh"
for version in "$@"; do
  moodle_known_sha256_for "${version}" >/dev/null ||
    fail "Moodle ${version} is not a pinned release in docker/fetch-moodle.sh; refusing to publish an unverified package"
done

curl -fsS "http://${REGISTRY}/v2/" >/dev/null 2>&1 ||
  fail "registry ${REGISTRY} is not answering; run bin/local-registry ensure in server-manager"

if ! docker buildx inspect "${BUILDER}" >/dev/null 2>&1; then
  docker buildx create --name "${BUILDER}" --driver docker-container \
    --driver-opt network=host --buildkitd-flags '--allow-insecure-entitlement=network.host' >/dev/null
fi

revision="$(git -C "${PROJECT_ROOT}" rev-parse --short=12 HEAD)"
if [[ -n "$(git -C "${PROJECT_ROOT}" status --porcelain)" ]]; then
  [[ "${ALLOW_DIRTY:-0}" == "1" ]] ||
    fail "working tree has uncommitted changes; commit first or set ALLOW_DIRTY=1"
  revision="${revision}-dirty"
fi
created="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

for version in "$@"; do
  echo "Publishing Moodle ${version} (${revision}) for ${PLATFORMS} to ${REPOSITORY}"
  docker buildx build \
    --builder "${BUILDER}" \
    --platform "${PLATFORMS}" \
    --build-arg "MOODLE_VERSION=${version}" \
    --label "org.opencontainers.image.title=frankenphp-moodle" \
    --label "org.opencontainers.image.version=${version}" \
    --label "org.opencontainers.image.revision=${revision}" \
    --label "org.opencontainers.image.created=${created}" \
    --tag "${REPOSITORY}:${version}" \
    --tag "${REPOSITORY}:${version}-${revision}" \
    --push \
    "${PROJECT_ROOT}"

  digest="$(docker buildx imagetools inspect "${REPOSITORY}:${version}" --format '{{.Manifest.Digest}}')"
  printf 'Published %s:%s  %s\n' "${REPOSITORY}" "${version}" "${digest}"
done
