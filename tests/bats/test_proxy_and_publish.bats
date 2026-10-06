#!/usr/bin/env bats

setup() {
  export APP_ROOT="${BATS_TEST_TMPDIR}/app"
  mkdir -p "${APP_ROOT}" "${BATS_TEST_TMPDIR}/bin"
  printf '#!/usr/bin/env bash\nexit 0\n' > "${BATS_TEST_TMPDIR}/bin/chown"
  chmod +x "${BATS_TEST_TMPDIR}/bin/chown"
  export PATH="${BATS_TEST_TMPDIR}/bin:${PATH}"
  sed '/^if \[\[ -z "${MOODLE_WEB_ROOT}" \]\]; then/,$d' docker/entrypoint.sh > "${BATS_TEST_TMPDIR}/functions.sh"
}

@test "Caddy serves HTTPS with its local CA unless MOODLE_TLS_MODE turns TLS off" {
  run grep -F 'import tls-{$MOODLE_TLS_MODE:internal}' docker/Caddyfile
  [ "${status}" -eq 0 ]

  run grep -Fx '(tls-off) {' docker/Caddyfile
  [ "${status}" -eq 0 ]

  run grep -F 'tls internal' docker/Caddyfile
  [ "${status}" -eq 0 ]
}

@test "entrypoint rejects an unknown MOODLE_TLS_MODE" {
  run grep -F 'internal | off) ;;' docker/entrypoint.sh
  [ "${status}" -eq 0 ]
}

@test "MOODLE_SSLPROXY adds one sslproxy line after wwwroot and removes it again" {
  command -v php >/dev/null || skip "php is not installed on this host"
  printf "<?php\n\$CFG = new stdClass();\n\$CFG->wwwroot   = 'https://moodle.test';\n\$CFG->dataroot = '/data';\n" > "${APP_ROOT}/config.php"

  run bash -c 'source "$1"; MOODLE_SSLPROXY=true; ensure_config_sslproxy; ensure_config_sslproxy' -- "${BATS_TEST_TMPDIR}/functions.sh"
  [ "${status}" -eq 0 ]
  [ "$(grep -c 'sslproxy' "${APP_ROOT}/config.php")" -eq 1 ]
  [ "$(sed -n 4p "${APP_ROOT}/config.php")" = '$CFG->sslproxy = true;' ]

  run bash -c 'source "$1"; MOODLE_SSLPROXY=false; ensure_config_sslproxy' -- "${BATS_TEST_TMPDIR}/functions.sh"
  [ "${status}" -eq 0 ]
  [ "$(grep -c 'sslproxy' "${APP_ROOT}/config.php")" -eq 0 ]
}

@test "MOODLE_SSLPROXY rejects values other than true or false" {
  printf "<?php\n" > "${APP_ROOT}/config.php"
  run bash -c 'source "$1"; MOODLE_SSLPROXY=yes; ensure_config_sslproxy' -- "${BATS_TEST_TMPDIR}/functions.sh"
  [ "${status}" -ne 0 ]
  [[ "${output}" == *"MOODLE_SSLPROXY must be true or false"* ]]
}

@test "publish refuses a Moodle release that is not checksum-pinned" {
  run scripts/publish-image.sh 5.2.2
  [ "${status}" -ne 0 ]
  [[ "${output}" == *"not a pinned release"* ]]
}

@test "publish refuses when the loopback registry is not answering" {
  PUBLISH_REGISTRY=127.0.0.1:1 run scripts/publish-image.sh 5.3.0
  [ "${status}" -ne 0 ]
  [[ "${output}" == *"bin/local-registry ensure"* ]]
}

@test "publish pushes only to the loopback registry by default" {
  run grep -Fx 'REGISTRY="${PUBLISH_REGISTRY:-localhost:5555}"' scripts/publish-image.sh
  [ "${status}" -eq 0 ]
}
