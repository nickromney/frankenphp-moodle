#!/usr/bin/env bats

setup() {
  if ! command -v docker >/dev/null 2>&1; then
    skip "docker is required"
  fi

  if ! docker info >/dev/null 2>&1; then
    skip "docker daemon is not reachable"
  fi
}

@test "FrankenPHP baseline passes end to end" {
  local results_dir
  results_dir="$(mktemp -d "/tmp/frankenphp-moodle-bats-XXXX")"

  run ./tests/docker/run-baseline.sh --results-dir "${results_dir}"

  [ "${status}" -eq 0 ]
  [[ "${output}" == *$'PASS\t'* ]]
  [[ "${output}" == *"FrankenPHP baseline passed"* ]]
}
