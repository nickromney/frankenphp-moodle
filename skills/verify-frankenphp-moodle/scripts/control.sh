#!/usr/bin/env bash
# shellcheck disable=SC2034 # VK_* settings are read by the sourced verify-lib.sh
set -euo pipefail

VK_SCRIPT="$0"
VK_APP="frankenphp-moodle"
VK_DESCRIPTION="Build and verify Moodle in an isolated, resource-capped local Compose project."
# shellcheck source=verify-lib.sh disable=SC1091
. "$(cd "$(dirname "$0")" && pwd)/verify-lib.sh"

VK_BROWSER_SKILL=1

vk_commands_help() {
  cat <<'HELP'
  launch                 preflight cached images, build current source, and start isolated containers
  doctor                 wait for Moodle's login route and check the owned app stack
  cleanup                remove this run's containers and volumes, keeping evidence
HELP
}
vk_sample_commands() { printf '%s\n' verify launch doctor cleanup; }
vk_paths() {
  local browsers
  browsers="$(vk_browsers)" || return $?
  STATE="$VK_BASE_DIR/$VK_RUN_ID/state"
  EVIDENCE="$VK_EVIDENCE_ROOT/$VK_RUN_ID"
  PROJECT="verify-moodle-$VK_RUN_ID"
  HTTP_PORT=""
  HTTPS_PORT=""
  SITE_URL=""
  if [ -f "$STATE/http-port" ]; then HTTP_PORT="$(cat "$STATE/http-port")"; fi
  if [ -f "$STATE/https-port" ]; then HTTPS_PORT="$(cat "$STATE/https-port")"; fi
  if [ -n "$HTTPS_PORT" ]; then SITE_URL="https://localhost:$HTTPS_PORT"; fi
}

safe_project_name() {
  case "$VK_RUN_ID" in
    ''|*[!A-Za-z0-9_-]*) vk_err "VERIFY_RUN_ID may contain only letters, digits, underscore, and hyphen"; return 2 ;;
  esac
}

compose() {
  APP_BIND_HOST=127.0.0.1 \
  APP_HTTP_PORT="$HTTP_PORT" \
  APP_HTTPS_PORT="$HTTPS_PORT" \
  MOODLE_HOST=localhost \
  SERVER_NAME=localhost \
  MOODLE_SITE_URL="$SITE_URL" \
  "${DOCKER_CMD:-docker}" compose -p "$PROJECT" \
    -f "$VK_ROOT/compose.yml" \
    -f "$VK_SKILL_DIR/compose.verify.yml" "$@"
}

vk_plan() {
  case "$1" in
    verify) vk_plan_line "preflight cached images, pinned Playwright engines, and disk; build current Moodle source; run app (1 CPU/1 GiB) and database (1 CPU/512 MiB) in isolated Compose project $PROJECT; prove login DOM in $(vk_browsers | tr '\n' ' ') plus theme, config, and tables; remove only project containers/volumes; retain evidence in $EVIDENCE" ;;
    launch) vk_plan_line "check Docker, cached images, and free-space floor before building; start project $PROJECT on loopback only" ;;
    doctor) vk_plan_line "wait for the run's Moodle login page to answer at $SITE_URL and report stack health" ;;
    cleanup) vk_plan_line "capture run logs, remove Compose project $PROJECT with its own volumes and locally built image; keep $EVIDENCE" ;;
    *) vk_unknown_command ;;
  esac
}

allocate_port() {
  python3 -c 'import socket; s = socket.socket(); s.bind(("127.0.0.1", 0)); print(s.getsockname()[1]); s.close()'
}

cmd_launch() {
  safe_project_name
  mkdir -p "$STATE" "$EVIDENCE"
  /bin/bash "$VK_SKILL_DIR/scripts/preflight.sh" "$VK_ROOT" "${PLAYWRIGHT_BROWSERS_PATH:-${VERIFY_BROWSER_CACHE:-}}" > "$EVIDENCE/preflight.txt" 2>&1 || {
    cat "$EVIDENCE/preflight.txt" >&2
    vk_fail "Docker preflight failed before any build or container start; see $EVIDENCE/preflight.txt"
    return 1
  }
  vk_mark_current
  vk_record_revision "$EVIDENCE/revision.txt"
  HTTP_PORT="$(allocate_port)"
  HTTPS_PORT="$(allocate_port)"
  while [ "$HTTPS_PORT" = "$HTTP_PORT" ]; do HTTPS_PORT="$(allocate_port)"; done
  printf '%s\n' "$HTTP_PORT" > "$STATE/http-port"
  printf '%s\n' "$HTTPS_PORT" > "$STATE/https-port"
  SITE_URL="https://localhost:$HTTPS_PORT"
  printf '%s\n' "$PROJECT" > "$STATE/project"
  compose build --pull=false app > "$EVIDENCE/build.log" 2>&1 || {
    cat "$EVIDENCE/build.log" >&2
    vk_fail "current source build failed; see $EVIDENCE/build.log"
    return 1
  }
  compose up -d --no-build --pull never > "$EVIDENCE/start.log" 2>&1 || {
    cat "$EVIDENCE/start.log" >&2
    vk_fail "isolated Moodle stack failed to start; see $EVIDENCE/start.log"
    return 1
  }
  vk_say "ready run=$VK_RUN_ID project=$PROJECT url=$SITE_URL evidence=$EVIDENCE"
}

cmd_doctor() {
  [ -f "$STATE/project" ] || { vk_fail "isolated Moodle stack is not launched; launch first"; return 1; }
  [ -n "$SITE_URL" ] || { vk_fail "Moodle URL is missing; launch first"; return 1; }
  if ! vk_wait_for 300 curl -kfsS -o /dev/null "$SITE_URL/login/index.php"; then
    compose logs --tail=200 app db > "$EVIDENCE/startup-failure.log" 2>&1 || true
    vk_fail "Moodle login route did not become ready at $SITE_URL; see $EVIDENCE/startup-failure.log"
    return 1
  fi
  vk_say "OK run=$VK_RUN_ID Moodle login route answers at $SITE_URL"
}

cmd_cleanup() {
  if [ -f "$STATE/project" ]; then
    compose logs --tail=300 app db > "$EVIDENCE/compose.log" 2>&1 || true
  fi
  if [ -f "$STATE/project" ]; then
    if ! compose down --rmi local -v --remove-orphans > "$EVIDENCE/cleanup.log" 2>&1; then
      vk_fail "isolated Compose cleanup failed; see $EVIDENCE/cleanup.log"
      return 1
    fi
  fi
  rm -rf "${STATE:?}"
  rmdir "$VK_BASE_DIR/$VK_RUN_ID" 2>/dev/null || true
  vk_clear_current
  vk_say "removed containers, volumes, and local image for run=$VK_RUN_ID; evidence kept at $EVIDENCE"
}

vk_verify_recipes() {
  local theme_asset_url browser playwright_python browsers
  browsers="$(vk_browsers)" || return $?
  cmd_doctor
  curl -kfsSL "$SITE_URL/login/index.php" -o "$EVIDENCE/login.html" || {
    vk_fail "Moodle login page request failed"
    return 1
  }
  vk_expect_contains "$EVIDENCE/login.html" "Moodle"
  vk_expect_contains "$EVIDENCE/login.html" 'name="username"'
  vk_expect_contains "$EVIDENCE/login.html" 'name="password"'
  theme_asset_url="$(python3 - "$SITE_URL" "$EVIDENCE/login.html" <<'PY'
import html
import re
import sys
import urllib.parse

base = sys.argv[1]
body = open(sys.argv[2], encoding="utf-8").read()
match = re.search(r"""(?:href|src)=["']([^"']*/theme/styles\.php[^"']*)""", body)
if match:
    print(urllib.parse.urljoin(base + "/", html.unescape(match.group(1))))
PY
)"
  if [ -z "$theme_asset_url" ]; then
    vk_fail "login page did not reference a Moodle theme stylesheet"
    return 1
  fi
  case "$theme_asset_url" in */theme/styles.php/lovely/*) ;; *) vk_fail "expected Lovely theme stylesheet, found $theme_asset_url"; return 1 ;; esac
  curl -kfsSL "$theme_asset_url" -o "$EVIDENCE/theme.css" || {
    vk_fail "Lovely theme stylesheet did not load: $theme_asset_url"
    return 1
  }
  vk_expect_file "$EVIDENCE/theme.css"
  playwright_python="${VERIFY_PLAYWRIGHT_PYTHON:-$VK_ROOT/.venv/bin/python}"
  for browser in $browsers; do
    MOODLE_VERIFY_URL="$SITE_URL" PLAYWRIGHT_BROWSERS_PATH="${PLAYWRIGHT_BROWSERS_PATH:-${VERIFY_BROWSER_CACHE:-}}" \
      "$playwright_python" "$VK_SKILL_DIR/tests/browser_journey.py" "$browser" \
      > "$EVIDENCE/$browser-browser.log" 2>&1 || {
      cat "$EVIDENCE/$browser-browser.log" >&2
      vk_fail "Moodle browser DOM journey failed in $browser; see $EVIDENCE/$browser-browser.log"
      return 1
    }
    vk_expect_contains "$EVIDENCE/$browser-browser.log" "PASS: login heading"
  done
  if ! compose exec -T app test -s /app/public/config.php > "$EVIDENCE/config-check.txt" 2>&1; then
    vk_fail "running Moodle container has no generated config.php"
    return 1
  fi
  if ! compose exec -T db mariadb-admin ping -h127.0.0.1 -uroot -prootpass --silent > "$EVIDENCE/database-ping.txt" 2>&1; then
    vk_fail "owned MariaDB service did not answer its health query"
    return 1
  fi
  if ! compose exec -T db mariadb -umoodle -pmoodlepass moodle -Nse \
    "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'moodle' AND table_name LIKE 'mdl_%';" \
    > "$EVIDENCE/table-count.txt" 2>&1; then
    vk_fail "could not query Moodle's installed tables"
    return 1
  fi
  local table_count
  table_count="$(tail -n 1 "$EVIDENCE/table-count.txt" | tr -d '[:space:]')"
  case "$table_count" in ''|*[!0-9]*) vk_fail "database returned an invalid Moodle table count: $table_count"; return 1 ;; esac
  if [ "$table_count" -lt 400 ]; then vk_fail "expected at least 400 Moodle tables, found $table_count"; return 1; fi
  vk_say "PASS: login page exposed username/password fields and loaded the Lovely stylesheet"
  vk_say "PASS: current app container has config.php; MariaDB ping succeeded; table_count=$table_count"
  "$VK_ROOT/verify-moodle.sh" --backend none --database mariadb --skip-web-check --skip-php-check \
    --url "$SITE_URL/login/index.php" --config-check-command \
    "docker compose -p $PROJECT -f $VK_ROOT/compose.yml -f $VK_SKILL_DIR/compose.verify.yml exec -T app test -s /app/public/config.php" \
    --db-ping-command \
    "docker compose -p $PROJECT -f $VK_ROOT/compose.yml -f $VK_SKILL_DIR/compose.verify.yml exec -T db mariadb-admin ping -h127.0.0.1 -uroot -prootpass --silent" \
    --db-query-command \
    "docker compose -p $PROJECT -f $VK_ROOT/compose.yml -f $VK_SKILL_DIR/compose.verify.yml exec -T db mariadb -umoodle -pmoodlepass moodle -Nse \"SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'moodle' AND table_name LIKE 'mdl_%';\"" \
    --table-min 400 --content-match "username" > "$EVIDENCE/verify-moodle.log" 2>&1 || {
    cat "$EVIDENCE/verify-moodle.log" >&2
    vk_fail "verify-moodle.sh acceptance check failed; see $EVIDENCE/verify-moodle.log"
    return 1
  }
  vk_expect_contains "$EVIDENCE/verify-moodle.log" "Moodle verification completed successfully"
}

vk_dispatch() {
  local cmd="$1"
  shift
  case "$cmd" in
    launch) cmd_launch ;;
    doctor) cmd_doctor ;;
    cleanup) cmd_cleanup ;;
    *) vk_unknown_command ;;
  esac
}
vk_main "$@"

