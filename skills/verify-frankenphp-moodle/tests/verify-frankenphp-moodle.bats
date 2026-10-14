#!/usr/bin/env bats

setup() {
  SKILL_DIR="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  ROOT="$(cd "$SKILL_DIR/../.." && pwd)"
  PREFLIGHT="$SKILL_DIR/scripts/preflight.sh"
}

@test "preflight refuses uncached images before compose can build or start" {
  local fake_docker="$BATS_TEST_TMPDIR/docker"
  cat > "$fake_docker" <<'SH'
#!/bin/sh
case "$1 $2" in
  "info ") exit 0 ;;
  "compose version") exit 0 ;;
  "image inspect") exit 1 ;;
esac
exit 2
SH
  chmod +x "$fake_docker"
  run env DOCKER_CMD="$fake_docker" /bin/bash "$PREFLIGHT" "$ROOT" "$BATS_TEST_TMPDIR/browsers"
  [ "$status" -ne 0 ]
  [[ "$output" == *"required image is not cached"* ]]
}

@test "preflight refuses an unavailable Docker CLI" {
  run env DOCKER_CMD="$BATS_TEST_TMPDIR/missing-docker" /bin/bash "$PREFLIGHT" "$ROOT" "$BATS_TEST_TMPDIR/browsers"
  [ "$status" -ne 0 ]
  [[ "$output" == *"Docker CLI is unavailable"* ]]
}

@test "invalid browser selection exits before creating state or evidence" {
  export VERIFY_BASE_DIR="$BATS_TEST_TMPDIR/base"
  export VERIFY_EVIDENCE_ROOT="$BATS_TEST_TMPDIR/evidence"
  export VERIFY_RUN_ID="moodle-contract-run"
  export VERIFY_BROWSERS="safari"
  run /bin/bash "$SKILL_DIR/scripts/control.sh" --execute verify
  [ "$status" -eq 2 ]
  [ ! -e "$VERIFY_BASE_DIR" ]
  [ ! -e "$VERIFY_EVIDENCE_ROOT" ]
}

