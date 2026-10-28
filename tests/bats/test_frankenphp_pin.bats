#!/usr/bin/env bats

setup() {
  check=skills/verify-frankenphp-moodle/scripts/check-php-image.sh
}

@test "default FrankenPHP selection matches the reviewed digest" {
  run env -u FRANKENPHP_IMAGE /bin/bash "$check" "$PWD"
  [ "$status" -eq 0 ]
}

@test "source check accepts the reviewed PHP 8.3 override" {
  run env FRANKENPHP_IMAGE='dunglas/frankenphp:1.13.2-php8.3.36-bookworm@sha256:f1654d31e7aa17a19b8ee1815e76503369acf975bae212bf1cffae27e96186ac' /bin/bash "$check" "$PWD"
  [ "$status" -eq 0 ]
}

@test "source check rejects vulnerable and unreviewed overrides" {
  for image in dunglas/frankenphp:php8.4-bookworm dunglas/frankenphp:php8.3-bookworm unknown; do
    run env FRANKENPHP_IMAGE="$image" /bin/bash "$check" "$PWD"
    [ "$status" -ne 0 ]
    [[ "$output" == *'not a reviewed image digest'* ]]
  done
}

@test "source check rejects a changed Dockerfile default" {
  mkdir -p "$BATS_TEST_TMPDIR/skills/verify-frankenphp-moodle"
  cp Dockerfile compose.yml "$BATS_TEST_TMPDIR/"
  cp skills/verify-frankenphp-moodle/compose.verify.yml "$BATS_TEST_TMPDIR/skills/verify-frankenphp-moodle/"
  sed 's/1.13.2-php8.4.27-bookworm/php8.4-bookworm/' Dockerfile > "$BATS_TEST_TMPDIR/Dockerfile"
  run env -u FRANKENPHP_IMAGE /bin/bash "$check" "$BATS_TEST_TMPDIR"
  [ "$status" -ne 0 ]
  [[ "$output" == *'differs from the reviewed policy'* ]]
}

@test "verification preflight rejects an unreviewed override before Docker" {
  run env VERIFY_BROWSERS=chromium FRANKENPHP_IMAGE=dunglas/frankenphp:php8.4-bookworm DOCKER_CMD=/nonexistent /bin/bash skills/verify-frankenphp-moodle/scripts/preflight.sh "$PWD" "$BATS_TEST_TMPDIR"
  [ "$status" -ne 0 ]
  [[ "$output" == *'not a reviewed image digest'* ]]
}

@test "verification Compose ignores a project dotenv override" {
  command -v docker >/dev/null || skip "Docker CLI unavailable"
  mkdir -p "$BATS_TEST_TMPDIR/project/skills/verify-frankenphp-moodle"
  cp compose.yml "$BATS_TEST_TMPDIR/project/"
  cp skills/verify-frankenphp-moodle/compose.verify.yml "$BATS_TEST_TMPDIR/project/skills/verify-frankenphp-moodle/"
  printf '%s\n' 'FRANKENPHP_IMAGE=dunglas/frankenphp:php8.4-bookworm' > "$BATS_TEST_TMPDIR/project/.env"
  cd "$BATS_TEST_TMPDIR/project"
  run env -u FRANKENPHP_IMAGE docker compose --env-file /dev/null -f compose.yml -f skills/verify-frankenphp-moodle/compose.verify.yml config --format json
  [ "$status" -eq 0 ]
  [[ "$output" == *'1.13.2-php8.4.27-bookworm@sha256:49369ff'* ]]
  [[ "$output" != *'dunglas/frankenphp:php8.4-bookworm'* ]]
}

@test "preflight rejects an unreviewed effective Compose selection" {
  cat > "$BATS_TEST_TMPDIR/docker" <<'SH'
#!/bin/sh
case "$1 $2" in
  'info '|'compose version') exit 0 ;;
  'compose --env-file') printf '{"services":{"app":{"build":{"context":"%s","dockerfile":"Dockerfile","args":{"FRANKENPHP_IMAGE":"unknown"}}}}}\n' "$TEST_ROOT" ;;
  *) exit 2 ;;
esac
SH
  chmod +x "$BATS_TEST_TMPDIR/docker"
  run env -u FRANKENPHP_IMAGE TEST_ROOT="$PWD" VERIFY_BROWSERS=chromium DOCKER_CMD="$BATS_TEST_TMPDIR/docker" /bin/bash skills/verify-frankenphp-moodle/scripts/preflight.sh "$PWD" "$BATS_TEST_TMPDIR"
  [ "$status" -ne 0 ]
  [[ "$output" == *'not a reviewed image digest: unknown'* ]]
}

@test "source check rejects an extra final stage" {
  mkdir -p "$BATS_TEST_TMPDIR/skills/verify-frankenphp-moodle"
  cp Dockerfile compose.yml "$BATS_TEST_TMPDIR/"
  cp skills/verify-frankenphp-moodle/compose.verify.yml "$BATS_TEST_TMPDIR/skills/verify-frankenphp-moodle/"
  printf '\nFROM dunglas/frankenphp:php8.4-bookworm\n' >> "$BATS_TEST_TMPDIR/Dockerfile"
  run env -u FRANKENPHP_IMAGE /bin/bash "$check" "$BATS_TEST_TMPDIR"
  [ "$status" -ne 0 ]
}

@test "preflight rejects a different effective context or Dockerfile" {
  cat > "$BATS_TEST_TMPDIR/docker" <<'SH'
#!/bin/sh
case "$1 $2" in
  'info '|'compose version') exit 0 ;;
  'compose --env-file') printf '{"services":{"app":{"build":{"context":"%s","dockerfile":"%s","args":{"FRANKENPHP_IMAGE":"%s"}}}}}\n' "$TEST_CONTEXT" "$TEST_DOCKERFILE" "$TEST_IMAGE" ;;
  *) exit 2 ;;
esac
SH
  chmod +x "$BATS_TEST_TMPDIR/docker"
  for scenario in context dockerfile; do
    context="$PWD"; dockerfile=Dockerfile
    if [ "$scenario" = context ]; then context="$BATS_TEST_TMPDIR"; else dockerfile=other.Dockerfile; fi
    run env -u FRANKENPHP_IMAGE TEST_CONTEXT="$context" TEST_DOCKERFILE="$dockerfile" TEST_IMAGE='dunglas/frankenphp:1.13.2-php8.4.27-bookworm@sha256:49369ff211d81dc30a15890d58c0651d639aef0d9c0a9b91bcc6f387a77bd7a2' VERIFY_BROWSERS=chromium DOCKER_CMD="$BATS_TEST_TMPDIR/docker" /bin/bash skills/verify-frankenphp-moodle/scripts/preflight.sh "$PWD" "$BATS_TEST_TMPDIR"
    [ "$status" -ne 0 ]
    [[ "$output" == *'unexpected Compose build context, Dockerfile, or target'* ]]
  done
}
