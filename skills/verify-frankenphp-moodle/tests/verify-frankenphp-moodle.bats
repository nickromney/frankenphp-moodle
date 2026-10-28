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
  "compose --env-file") printf '{"services":{"app":{"build":{"context":"%s","dockerfile":"Dockerfile","args":{"FRANKENPHP_IMAGE":"dunglas/frankenphp:1.13.2-php8.4.27-bookworm@sha256:49369ff211d81dc30a15890d58c0651d639aef0d9c0a9b91bcc6f387a77bd7a2"}}}}}\n' "$TEST_ROOT" ;;
  "image inspect") exit 1 ;;
esac
exit 0
SH
  cat > "$BATS_TEST_TMPDIR/df" <<'SH'
#!/bin/sh
printf 'Filesystem 1024-blocks Used Available Capacity Mounted\nfixture 50000000 1 49999999 1%% /\n'
SH
  chmod +x "$fake_docker" "$BATS_TEST_TMPDIR/df"
  run env -u FRANKENPHP_IMAGE PATH="$BATS_TEST_TMPDIR:$PATH" TEST_ROOT="$ROOT" VERIFY_BROWSERS=chromium DOCKER_CMD="$fake_docker" /bin/bash "$PREFLIGHT" "$ROOT" "$BATS_TEST_TMPDIR/browsers"
  [ "$status" -ne 0 ] || return 1
  [[ "$output" == *"required image is not cached"* ]] || return 1
}

@test "preflight refuses an unavailable Docker CLI" {
  run env VERIFY_BROWSERS=chromium DOCKER_CMD="$BATS_TEST_TMPDIR/missing-docker" /bin/bash "$PREFLIGHT" "$ROOT" "$BATS_TEST_TMPDIR/browsers"
  [ "$status" -ne 0 ] || return 1
  [[ "$output" == *"Docker CLI is unavailable"* ]] || return 1
}

@test "invalid browser selection exits before creating state or evidence" {
  export VERIFY_BASE_DIR="$BATS_TEST_TMPDIR/base"
  export VERIFY_EVIDENCE_ROOT="$BATS_TEST_TMPDIR/evidence"
  export VERIFY_RUN_ID="moodle-contract-run"
  export VERIFY_BROWSERS="safari"
  run /bin/bash "$SKILL_DIR/scripts/control.sh" --execute verify
  [ "$status" -eq 2 ] || return 1
  [ ! -e "$VERIFY_BASE_DIR" ] || return 1
  [ ! -e "$VERIFY_EVIDENCE_ROOT" ] || return 1
}


@test "owned compose ignores ambient installation settings and project dotenv" {
  local fake_docker="$BATS_TEST_TMPDIR/docker"
  cat > "$fake_docker" <<'SH'
#!/bin/sh
printf '%s\n' "auto=$MOODLE_AUTO_INSTALL db=$MOODLE_DB_NAME user=$MOODLE_DB_USER password=$MOODLE_DB_PASSWORD theme=$MOODLE_THEME version=$MOODLE_VERSION package=$MOODLE_PACKAGE_URL"
printf '%s\n' "$@"
SH
  chmod +x "$fake_docker"
  # shellcheck disable=SC2016 # Child Bash expands the isolated function test.
  run env DOCKER_CMD="$fake_docker" MOODLE_AUTO_INSTALL=false MOODLE_DB_NAME=operator \
    MOODLE_DB_USER=operator MOODLE_DB_PASSWORD=private MOODLE_THEME=boost \
    MOODLE_VERSION=other MOODLE_PACKAGE_URL=https://invalid.test/moodle \
    /bin/bash -c '
      loader="$(mktemp)"
      sed "/^vk_main /d" "$0" > "$loader"
      . "$loader"
      rm -f "$loader"
      VK_ROOT="$1"; VK_SKILL_DIR="$2"; PROJECT=verify-moodle-fixture
      HTTP_PORT=18080; HTTPS_PORT=18443; SITE_URL=https://localhost:18443
      compose config
    ' "$SKILL_DIR/scripts/control.sh" "$ROOT" "$SKILL_DIR"
  [ "$status" -eq 0 ] || return 1
  [[ "$output" == *"auto=true db=moodle user=moodle password=moodlepass theme=lovely version=5.2.4 package="* ]] || return 1
  [[ "$output" == *$'--env-file\n/dev/null'* ]] || return 1
}

@test "invalid build network exits before creating state or evidence" {
  run env VERIFY_BASE_DIR="$BATS_TEST_TMPDIR/base" VERIFY_EVIDENCE_ROOT="$BATS_TEST_TMPDIR/evidence" VERIFY_BUILD_NETWORK=host /bin/bash "$SKILL_DIR/scripts/control.sh" --execute verify
  [ "$status" -eq 2 ] || return 1
  [[ "$output" == *"VERIFY_BUILD_NETWORK must be none or default"* ]] || return 1
  [ ! -e "$BATS_TEST_TMPDIR/base" ] || return 1
  [ ! -e "$BATS_TEST_TMPDIR/evidence" ] || return 1
}

@test "build network defaults to none and default opt-in is disclosed in the plan" {
  run env VERIFY_BUILD_NETWORK=none /bin/bash "$SKILL_DIR/scripts/control.sh" --dry-run verify
  [ "$status" -eq 0 ] || return 1
  [[ "$output" == *"build network=none"* ]] || return 1
  run env VERIFY_BUILD_NETWORK=default /bin/bash "$SKILL_DIR/scripts/control.sh" --dry-run verify
  [ "$status" -eq 0 ] || return 1
  [[ "$output" == *"build network=default"* ]] || return 1
  [[ "$output" == *"permits package downloads, never image pulls"* ]] || return 1
}

@test "generated mixed-case run IDs map to distinct valid Compose projects" {
  local first second
  run env VERIFY_RUN_ID=20261017T094751Z-60883-32185-13180 /bin/bash "$SKILL_DIR/scripts/control.sh" --dry-run launch
  [ "$status" -eq 0 ] || return 1
  first="$(printf '%s' "$output" | sed -n 's/.*start project \(verify-moodle-[a-f0-9]*\) on loopback only.*/\1/p')"
  [[ "$first" =~ ^verify-moodle-[a-f0-9]{24}$ ]] || return 1
  run env VERIFY_RUN_ID=20261017t094751z-60883-32185-13180 /bin/bash "$SKILL_DIR/scripts/control.sh" --dry-run launch
  [ "$status" -eq 0 ] || return 1
  second="$(printf '%s' "$output" | sed -n 's/.*start project \(verify-moodle-[a-f0-9]*\) on loopback only.*/\1/p')"
  [[ "$second" =~ ^verify-moodle-[a-f0-9]{24}$ ]] || return 1
  [ "$first" != "$second" ] || return 1
}

@test "Firefox preflight refuses missing NSS certutil without requiring it for Chromium" {
  local tool path_dir="$BATS_TEST_TMPDIR/path"
  mkdir -p "$path_dir"
  for tool in awk curl df dirname grep python3 tr; do
    ln -s "$(command -v "$tool")" "$path_dir/$tool"
  done
  run env PATH="$path_dir" VERIFY_BROWSERS="chromium firefox" DOCKER_CMD=missing-docker \
    /bin/bash "$PREFLIGHT" "$ROOT" "$BATS_TEST_TMPDIR/browsers"
  [ "$status" -ne 0 ] || return 1
  [[ "$output" == *"NSS certutil is required"* ]] || return 1
  run env PATH="$path_dir" VERIFY_BROWSERS=chromium DOCKER_CMD=missing-docker \
    /bin/bash "$PREFLIGHT" "$ROOT" "$BATS_TEST_TMPDIR/browsers"
  [ "$status" -ne 0 ] || return 1
  [[ "$output" == *"Docker CLI is unavailable"* ]] || return 1
}

@test "acceptance child receives only its owned CA without changing caller trust" {
  local fixture="$BATS_TEST_TMPDIR/app"
  mkdir -p "$fixture"
  cat > "$fixture/verify-moodle.sh" <<'SH'
#!/bin/sh
printf 'child-ca=%s\n' "$CURL_CA_BUNDLE"
printf 'argument=%s\n' "$@"
SH
  chmod +x "$fixture/verify-moodle.sh"
  # shellcheck disable=SC2016 # Child Bash expands the actual helper and fixture.
  run env CURL_CA_BUNDLE=operator-ca /bin/bash -c '
    loader="$(mktemp)"
    sed "/^vk_main /d" "$0" > "$loader"
    . "$loader"
    rm -f "$loader"
    VK_ROOT="$1"; EVIDENCE="$2"
    run_moodle_acceptance --url https://localhost:18443/login/index.php
    printf "caller-ca=%s\n" "$CURL_CA_BUNDLE"
  ' "$SKILL_DIR/scripts/control.sh" "$fixture" "$BATS_TEST_TMPDIR/evidence"
  [ "$status" -eq 0 ] || return 1
  [[ "$output" == *"child-ca=$BATS_TEST_TMPDIR/evidence/caddy-root.crt"* ]] || return 1
  [[ "$output" == *"argument=https://localhost:18443/login/index.php"* ]] || return 1
  [[ "$output" == *"caller-ca=operator-ca"* ]] || return 1
}
