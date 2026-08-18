#!/usr/bin/env bats

PREFLIGHT="./docker/tls-preflight.sh"

utc_stamp() {
  python3 -c "from datetime import datetime, timedelta, timezone; print((datetime.now(timezone.utc)+timedelta(seconds=int('${1}'))).strftime('%Y%m%d%H%M%SZ'))"
}

mint_cert() {
  local dest_dir="$1"
  local not_before="$2"
  local not_after="$3"

  mkdir -p "${dest_dir}"
  openssl req -x509 -newkey rsa:2048 -nodes \
    -keyout "${dest_dir}/key.pem" \
    -out "${dest_dir}/cert.pem" \
    -subj "/CN=tls-preflight.test" \
    -not_before "${not_before}" \
    -not_after "${not_after}" \
    >/dev/null 2>&1
}

serve_tls() {
  local cert_dir="$1"
  local port="$2"

  python3 - "${cert_dir}/cert.pem" "${cert_dir}/key.pem" "${port}" <<'PY' &
import http.server
import ssl
import sys

certfile, keyfile, port = sys.argv[1], sys.argv[2], int(sys.argv[3])
httpd = http.server.HTTPServer(("127.0.0.1", port), http.server.BaseHTTPRequestHandler)
context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
context.load_cert_chain(certfile=certfile, keyfile=keyfile)
httpd.socket = context.wrap_socket(httpd.socket, server_side=True)
httpd.serve_forever()
PY
  SERVER_PID=$!
  sleep 0.3
}

setup() {
  TEST_TMPDIR="$(mktemp -d "/tmp/tls-preflight-XXXX")"
  SERVER_PID=""
}

teardown() {
  if [[ -n "${SERVER_PID}" ]]; then
    kill "${SERVER_PID}" >/dev/null 2>&1 || true
    wait "${SERVER_PID}" >/dev/null 2>&1 || true
  fi
  rm -rf "${TEST_TMPDIR}"
}

@test "tls-preflight.sh has valid bash syntax" {
  run bash -n "${PREFLIGHT}"
  [ "${status}" -eq 0 ]
}

@test "a certificate with remaining lifetime passes PEM preflight" {
  mint_cert "${TEST_TMPDIR}/valid" "$(utc_stamp -3600)" "$(utc_stamp 2592000)"

  run "${PREFLIGHT}" --pem "${TEST_TMPDIR}/valid/cert.pem"
  [ "${status}" -eq 0 ]
  [[ "${output}" == *"TLS certificate is valid"* ]]
}

@test "an expired certificate fails PEM preflight" {
  mint_cert "${TEST_TMPDIR}/expired" "$(utc_stamp -172800)" "$(utc_stamp -86400)"

  run "${PREFLIGHT}" --pem "${TEST_TMPDIR}/expired/cert.pem"
  [ "${status}" -eq 1 ]
  [[ "${output}" == *"expired"* ]]
}

@test "a certificate that expires inside the remaining-lifetime floor fails PEM preflight" {
  mint_cert "${TEST_TMPDIR}/soon" "$(utc_stamp -3600)" "$(utc_stamp 60)"

  TLS_PREFLIGHT_MIN_REMAINING_SECONDS=300 \
    run "${PREFLIGHT}" --pem "${TEST_TMPDIR}/soon/cert.pem"
  [ "${status}" -eq 1 ]
  [[ "${output}" == *"expires too soon"* ]]
}

@test "an expired live peer certificate fails URL preflight" {
  if ! command -v python3 >/dev/null 2>&1; then
    skip "python3 is required for the TLS fixture"
  fi

  mint_cert "${TEST_TMPDIR}/expired" "$(utc_stamp -172800)" "$(utc_stamp -86400)"
  local port="$((21000 + (RANDOM % 1000)))"
  serve_tls "${TEST_TMPDIR}/expired" "${port}"

  run "${PREFLIGHT}" --url "https://127.0.0.1:${port}/"
  [ "${status}" -eq 1 ]
  [[ "${output}" == *"expired"* ]]
}

@test "a valid live peer certificate passes URL preflight" {
  if ! command -v python3 >/dev/null 2>&1; then
    skip "python3 is required for the TLS fixture"
  fi

  mint_cert "${TEST_TMPDIR}/valid" "$(utc_stamp -3600)" "$(utc_stamp 2592000)"
  local port="$((21000 + (RANDOM % 1000)))"
  serve_tls "${TEST_TMPDIR}/valid" "${port}"

  run "${PREFLIGHT}" --url "https://127.0.0.1:${port}/"
  [ "${status}" -eq 0 ]
  [[ "${output}" == *"TLS certificate is valid"* ]]
}

@test "prune removes expired Caddy site certificates and keeps valid ones" {
  local cert_root="${TEST_TMPDIR}/certificates"
  mint_cert "${TEST_TMPDIR}/expired" "$(utc_stamp -172800)" "$(utc_stamp -86400)"
  mint_cert "${TEST_TMPDIR}/valid" "$(utc_stamp -3600)" "$(utc_stamp 2592000)"

  mkdir -p "${cert_root}/local/expired.test" "${cert_root}/local/valid.test"
  cp "${TEST_TMPDIR}/expired/cert.pem" "${cert_root}/local/expired.test/expired.test.crt"
  cp "${TEST_TMPDIR}/valid/cert.pem" "${cert_root}/local/valid.test/valid.test.crt"

  run "${PREFLIGHT}" prune "${cert_root}"
  [ "${status}" -eq 0 ]
  [ ! -d "${cert_root}/local/expired.test" ]
  [ -f "${cert_root}/local/valid.test/valid.test.crt" ]
}

@test "compose-up and baseline refuse to advertise a site until TLS preflight passes" {
  run grep -F 'tls_preflight_check_url' tests/docker/compose-up.sh
  [ "${status}" -eq 0 ]

  run grep -F 'tls_preflight_check_url' tests/docker/run-baseline.sh
  [ "${status}" -eq 0 ]
}

@test "entrypoint prunes expired Caddy certificates before FrankenPHP starts" {
  run grep -F 'tls_preflight_prune_expired_certs' docker/entrypoint.sh
  [ "${status}" -eq 0 ]
}
