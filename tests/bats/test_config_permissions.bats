#!/usr/bin/env bats

setup() {
  export APP_ROOT="${BATS_TEST_TMPDIR}/app"
  export MOODLE_CONFIG_ROOT="${BATS_TEST_TMPDIR}/config"
  mkdir -p "${APP_ROOT}" "${MOODLE_CONFIG_ROOT}" "${BATS_TEST_TMPDIR}/bin"
  # Ownership is container-specific; keep the fixture limited to file modes.
  printf '#!/usr/bin/env bash\nexit 0\n' > "${BATS_TEST_TMPDIR}/bin/chown"
  chmod +x "${BATS_TEST_TMPDIR}/bin/chown"
  export PATH="${BATS_TEST_TMPDIR}/bin:${PATH}"
  sed '/^if \[\[ -z "${MOODLE_WEB_ROOT}" \]\]; then/,$d' docker/entrypoint.sh > "${BATS_TEST_TMPDIR}/functions.sh"
}

@test "persisted credential snapshot and restored config are private and retain contents" {
  printf 'synthetic database credential\n' > "${APP_ROOT}/config.php"
  chmod 0644 "${APP_ROOT}/config.php"
  run bash -c 'source "$1"; persist_config_snapshot; rm "$MOODLE_CONFIG_FILE"; restore_persisted_config' -- "${BATS_TEST_TMPDIR}/functions.sh"
  [ "${status}" -eq 0 ]
  run python3 - "${APP_ROOT}/config.php" "${MOODLE_CONFIG_ROOT}/config.php" <<'PY'
import pathlib, stat, sys
for path in map(pathlib.Path, sys.argv[1:]):
    assert stat.S_IMODE(path.stat().st_mode) == 0o600
    assert path.read_text() == "synthetic database credential\n"
PY
  [ "${status}" -eq 0 ]
}

@test "snapshot hardens a previously permissive persisted config" {
  printf 'new synthetic credential\n' > "${APP_ROOT}/config.php"
  printf 'old synthetic credential\n' > "${MOODLE_CONFIG_ROOT}/config.php"
  chmod 0644 "${MOODLE_CONFIG_ROOT}/config.php"
  run bash -c 'source "$1"; persist_config_snapshot' -- "${BATS_TEST_TMPDIR}/functions.sh"
  [ "${status}" -eq 0 ]
  run python3 - "${MOODLE_CONFIG_ROOT}/config.php" <<'PY'
import pathlib, stat, sys
path = pathlib.Path(sys.argv[1])
assert stat.S_IMODE(path.stat().st_mode) == 0o600
assert path.read_text() == "new synthetic credential\n"
PY
  [ "${status}" -eq 0 ]
}
