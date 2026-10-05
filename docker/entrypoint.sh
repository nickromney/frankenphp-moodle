#!/usr/bin/env bash

set -euo pipefail

# config.php contains database credentials; newly created files stay private.
umask 0077

APP_ROOT="${APP_ROOT:-/app/public}"
MOODLE_DATA_ROOT="${MOODLE_DATA_ROOT:-/app/moodledata}"
MOODLE_CONFIG_ROOT="${MOODLE_CONFIG_ROOT:-/app/config}"
MOODLE_CONFIG_FILE="${APP_ROOT}/config.php"
PERSISTED_CONFIG_FILE="${MOODLE_CONFIG_ROOT}/config.php"

APP_HTTP_PORT="${APP_HTTP_PORT:-80}"
APP_HTTPS_PORT="${APP_HTTPS_PORT:-443}"
MOODLE_HOST="${MOODLE_HOST:-moodle.docker.test.127.0.0.1.sslip.io}"
MOODLE_WEB_ROOT="${MOODLE_WEB_ROOT:-}"
MOODLE_AUTO_INSTALL="${MOODLE_AUTO_INSTALL:-true}"
MOODLE_DB_HOST="${MOODLE_DB_HOST:-db}"
MOODLE_DB_PORT="${MOODLE_DB_PORT:-3306}"
MOODLE_DB_NAME="${MOODLE_DB_NAME:-moodle}"
MOODLE_DB_USER="${MOODLE_DB_USER:-moodle}"
MOODLE_DB_PASSWORD="${MOODLE_DB_PASSWORD:-moodlepass}"
MOODLE_DB_WAIT_ATTEMPTS="${MOODLE_DB_WAIT_ATTEMPTS:-60}"
MOODLE_SITE_SCHEME="${MOODLE_SITE_SCHEME:-https}"
MOODLE_SITE_URL="${MOODLE_SITE_URL:-}"
MOODLE_SITE_FULLNAME="${MOODLE_SITE_FULLNAME:-Moodle}"
MOODLE_SITE_SHORTNAME="${MOODLE_SITE_SHORTNAME:-Moodle}"
MOODLE_ADMIN_USER="${MOODLE_ADMIN_USER:-admin}"
MOODLE_ADMIN_PASSWORD="${MOODLE_ADMIN_PASSWORD:-Adminpass123!}"
MOODLE_ADMIN_EMAIL="${MOODLE_ADMIN_EMAIL:-demo@moodle.test}"
MOODLE_THEME="${MOODLE_THEME:-lovely}"

function info() {
  printf '[entrypoint] %s\n' "$1"
}

function fail() {
  printf '[entrypoint] %s\n' "$1" >&2
  exit 1
}

function default_site_url() {
  local port=""

  case "${MOODLE_SITE_SCHEME}" in
    https)
      port="${APP_HTTPS_PORT}"
      if [[ "${port}" == "443" ]]; then
        printf '%s://%s\n' "${MOODLE_SITE_SCHEME}" "${MOODLE_HOST}"
      else
        printf '%s://%s:%s\n' "${MOODLE_SITE_SCHEME}" "${MOODLE_HOST}" "${port}"
      fi
      ;;
    http)
      port="${APP_HTTP_PORT}"
      if [[ "${port}" == "80" ]]; then
        printf '%s://%s\n' "${MOODLE_SITE_SCHEME}" "${MOODLE_HOST}"
      else
        printf '%s://%s:%s\n' "${MOODLE_SITE_SCHEME}" "${MOODLE_HOST}" "${port}"
      fi
      ;;
    *)
      fail "unsupported MOODLE_SITE_SCHEME: ${MOODLE_SITE_SCHEME}"
      ;;
  esac
}

function restore_persisted_config() {
  if [[ -f "${PERSISTED_CONFIG_FILE}" ]]; then
    rm -f "${MOODLE_CONFIG_FILE}"
    install -m 0600 "${PERSISTED_CONFIG_FILE}" "${MOODLE_CONFIG_FILE}"
    chown www-data:www-data "${MOODLE_CONFIG_FILE}" || true
    chmod 0600 "${MOODLE_CONFIG_FILE}"
  fi
}

function persist_config_snapshot() {
  [[ -f "${MOODLE_CONFIG_FILE}" ]] || return 0
  install -m 0600 "${MOODLE_CONFIG_FILE}" "${PERSISTED_CONFIG_FILE}"
  chown www-data:www-data "${PERSISTED_CONFIG_FILE}" || true
  chmod 0600 "${PERSISTED_CONFIG_FILE}"
}

function ensure_config_site_url() {
  [[ -f "${MOODLE_CONFIG_FILE}" ]] || return 0

  MOODLE_CONFIG_FILE_PATH="${MOODLE_CONFIG_FILE}" \
  MOODLE_EXPECTED_SITE_URL="${MOODLE_SITE_URL}" \
  php <<'PHP'
<?php
$path = getenv("MOODLE_CONFIG_FILE_PATH");
$expected = getenv("MOODLE_EXPECTED_SITE_URL");
$contents = file_get_contents($path);
if ($contents === false) {
    fwrite(STDERR, "failed to read config.php\n");
    exit(1);
}

$updated = preg_replace(
    "/^\\\$CFG->wwwroot\\s*=\\s*'[^']*';$/m",
    "\$CFG->wwwroot   = '" . str_replace("'", "\\'", $expected) . "';",
    $contents,
    1,
    $count
);

if ($updated === null || $count !== 1) {
    fwrite(STDERR, "failed to update \$CFG->wwwroot in config.php\n");
    exit(1);
}

if ($updated !== $contents && file_put_contents($path, $updated) === false) {
    fwrite(STDERR, "failed to write config.php\n");
    exit(1);
}
PHP

  chown www-data:www-data "${MOODLE_CONFIG_FILE}" || true
  chmod 0600 "${MOODLE_CONFIG_FILE}"
}

function wait_for_database() {
  local attempts="${MOODLE_DB_WAIT_ATTEMPTS}"

  while (( attempts > 0 )); do
    # shellcheck disable=SC2016
    if php -r '
      mysqli_report(MYSQLI_REPORT_OFF);
      $host = getenv("MOODLE_DB_HOST") ?: "db";
      $port = (int) (getenv("MOODLE_DB_PORT") ?: 3306);
      $user = getenv("MOODLE_DB_USER") ?: "moodle";
      $pass = getenv("MOODLE_DB_PASSWORD") ?: "moodlepass";
      $mysqli = @mysqli_init();
      if (!$mysqli || !@$mysqli->real_connect($host, $user, $pass, null, $port)) {
          exit(1);
      }
      $mysqli->close();
    ' >/dev/null 2>&1; then
      return 0
    fi

    attempts=$((attempts - 1))
    sleep 1
  done

  fail "database did not become ready in time"
}

function install_moodle_if_needed() {
  [[ "${MOODLE_AUTO_INSTALL}" == "true" ]] || return 0
  [[ -f "${PERSISTED_CONFIG_FILE}" ]] && return 0

  wait_for_database
  info "installing Moodle"

  php "${APP_ROOT}/admin/cli/install.php" \
    --lang=en \
    --wwwroot="${MOODLE_SITE_URL}" \
    --dataroot="${MOODLE_DATA_ROOT}" \
    --dbtype=mariadb \
    --dbhost="${MOODLE_DB_HOST}" \
    --dbname="${MOODLE_DB_NAME}" \
    --dbuser="${MOODLE_DB_USER}" \
    --dbpass="${MOODLE_DB_PASSWORD}" \
    --fullname="${MOODLE_SITE_FULLNAME}" \
    --shortname="${MOODLE_SITE_SHORTNAME}" \
    --adminuser="${MOODLE_ADMIN_USER}" \
    --adminpass="${MOODLE_ADMIN_PASSWORD}" \
    --adminemail="${MOODLE_ADMIN_EMAIL}" \
    --non-interactive \
    --agree-license

  [[ -f "${MOODLE_CONFIG_FILE}" ]] || fail "Moodle install completed without writing config.php"

  persist_config_snapshot
}

function upgrade_moodle_if_needed() {
  [[ "${MOODLE_AUTO_INSTALL}" == "true" ]] || return 0
  [[ -f "${MOODLE_CONFIG_FILE}" ]] || return 0

  # A rebuilt image can ship plugins (such as the bundled theme) that an existing database
  # has never seen; without this, Moodle parks admins on the plugin-check page instead of
  # the site. No-ops in a few seconds when nothing is pending.
  wait_for_database
  info "running Moodle upgrade check"
  php "${APP_ROOT}/admin/cli/upgrade.php" --non-interactive
}

function prune_expired_caddy_certs() {
  # shellcheck source=docker/tls-preflight.sh
  source /usr/local/bin/tls-preflight.sh
  tls_preflight_prune_expired_certs /data/caddy/certificates
}

function configure_theme() {
  [[ -f "${MOODLE_CONFIG_FILE}" ]] || return 0
  [[ -n "${MOODLE_THEME}" ]] || return 0

  if [[ ! -f "${MOODLE_WEB_ROOT}/theme/${MOODLE_THEME}/config.php" ]]; then
    info "WARNING: theme '${MOODLE_THEME}' does not exist under ${MOODLE_WEB_ROOT}/theme; keeping the current theme"
    return 0
  fi

  local current_theme
  current_theme="$(php "${APP_ROOT}/admin/cli/cfg.php" --name=theme 2>/dev/null || true)"
  if [[ "${current_theme}" == "${MOODLE_THEME}" ]]; then
    return 0
  fi

  info "setting default theme to ${MOODLE_THEME}"
  php "${APP_ROOT}/admin/cli/cfg.php" --name=theme --set="${MOODLE_THEME}"
  php "${APP_ROOT}/admin/cli/purge_caches.php"
}

if [[ -z "${MOODLE_WEB_ROOT}" ]]; then
  if [[ -d "${APP_ROOT}/public" ]]; then
    MOODLE_WEB_ROOT="${APP_ROOT}/public"
  else
    MOODLE_WEB_ROOT="${APP_ROOT}"
  fi
fi
export MOODLE_WEB_ROOT

if [[ -z "${MOODLE_SITE_URL}" ]]; then
  MOODLE_SITE_URL="$(default_site_url)"
fi

install -d -m 0775 -o www-data -g www-data "${MOODLE_DATA_ROOT}"
install -d -m 0700 -o www-data -g www-data "${MOODLE_CONFIG_ROOT}"
chown -R www-data:www-data "${MOODLE_DATA_ROOT}" "${MOODLE_CONFIG_ROOT}" || true
prune_expired_caddy_certs

restore_persisted_config
ensure_config_site_url
install_moodle_if_needed
upgrade_moodle_if_needed
configure_theme
ensure_config_site_url
persist_config_snapshot

exec docker-php-entrypoint "$@"
