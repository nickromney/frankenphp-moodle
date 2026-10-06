#!/usr/bin/env bash
# Download and unpack a Moodle release package.
#
# Usage: fetch-moodle.sh <version> <destination> [series] [package-url] [sha256]
#
# <version> is a Moodle release number such as 5.2.4 or 5.3.0. Moodle names
# the first package of a major release without the patch digit
# (moodle-5.3.tgz, not moodle-5.3.0.tgz), so X.Y.0 is normalised here.
# [series] defaults to the stable channel for the version (5.3.0 -> stable503).
# [sha256] defaults to the pinned checksum for known releases; unknown releases
# are downloaded unverified with a warning.
#
# Sourcing this file only defines the functions, so tests can call them.

set -euo pipefail

MOODLE_MIRRORS=(
  "https://download.moodle.org/download.php/direct"
  "https://packaging.moodle.org"
)

# Releases this image supports and verifies. Keep in step with the tags on
# https://github.com/moodle/moodle/tags: version|git tag commit|package sha256
MOODLE_KNOWN_RELEASES=(
  "5.2.4|2df605b1e093248e8f8d1e2fc081fb3b1f65665f|8569b63f1e97416ecb67ec75767dd20675892c7a62a5e90d1647366fddf873cf"
  "5.3.0|42622298fe06f9626d988d60b2bf589bd8f850e8|7e5edf110555956571f40e42acffde0eb23681ebebd212a2fec0fe7d795dd511"
)

function moodle_series_for() {
  local version="$1" major minor
  if [[ ! "${version}" =~ ^([0-9]+)\.([0-9]+)(\.[0-9]+)?$ ]]; then
    echo "Error: unsupported Moodle version '${version}' (expected X.Y or X.Y.Z)." >&2
    return 1
  fi
  major="${BASH_REMATCH[1]}"
  minor="${BASH_REMATCH[2]}"
  printf 'stable%s%02d\n' "${major}" "$((10#${minor}))"
}

function moodle_package_name_for() {
  local version="$1"
  if [[ "${version}" =~ ^([0-9]+\.[0-9]+)\.0$ ]]; then
    version="${BASH_REMATCH[1]}"
  fi
  printf 'moodle-%s.tgz\n' "${version}"
}

function moodle_known_sha256_for() {
  local version="$1" entry
  if [[ "${version}" =~ ^[0-9]+\.[0-9]+$ ]]; then
    version="${version}.0"
  fi
  for entry in "${MOODLE_KNOWN_RELEASES[@]}"; do
    if [[ "${entry%%|*}" == "${version}" ]]; then
      printf '%s\n' "${entry##*|}"
      return 0
    fi
  done
  return 1
}

function moodle_fetch() {
  local version="$1" destination="$2" series="${3:-}" package_url="${4:-}" sha256="${5:-}"
  local package archive url
  local -a urls=()

  series="${series:-$(moodle_series_for "${version}")}"
  package="$(moodle_package_name_for "${version}")"
  if [[ -z "${sha256}" && -z "${package_url}" ]]; then
    sha256="$(moodle_known_sha256_for "${version}" || true)"
  fi

  if [[ -n "${package_url}" ]]; then
    urls=("${package_url}")
  else
    for url in "${MOODLE_MIRRORS[@]}"; do
      urls+=("${url}/${series}/${package}")
    done
  fi

  archive="$(mktemp)"
  for url in "${urls[@]}"; do
    echo "Fetching Moodle ${version}: ${url}" >&2
    if curl -fsSL --retry 3 --retry-delay 2 -o "${archive}" "${url}"; then
      break
    fi
    echo "Warning: download failed from ${url}" >&2
    : >"${archive}"
  done

  if [[ ! -s "${archive}" ]]; then
    echo "Error: could not download Moodle ${version} from any mirror." >&2
    rm -f "${archive}"
    return 1
  fi

  if [[ -n "${sha256}" ]]; then
    if ! echo "${sha256}  ${archive}" | sha256sum -c - >/dev/null; then
      echo "Error: Moodle ${version} package checksum does not match ${sha256}." >&2
      rm -f "${archive}"
      return 1
    fi
    echo "Verified Moodle ${version} package sha256 ${sha256}" >&2
  else
    echo "Warning: Moodle ${version} is not a pinned release; package checksum not verified." >&2
  fi

  mkdir -p "${destination}"
  tar -xzf "${archive}" --strip-components=1 -C "${destination}"
  rm -f "${archive}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  moodle_fetch "$@"
fi
