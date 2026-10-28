#!/usr/bin/env bash
set -euo pipefail
root="${1:?usage: check-php-image.sh PROJECT_ROOT}"
reviewed='dunglas/frankenphp:1.13.2-php8.4.27-bookworm@sha256:49369ff211d81dc30a15890d58c0651d639aef0d9c0a9b91bcc6f387a77bd7a2'
selected="${FRANKENPHP_IMAGE:-$reviewed}"
case "$selected" in
  "$reviewed"|'dunglas/frankenphp:1.13.2-php8.3.36-bookworm@sha256:f1654d31e7aa17a19b8ee1815e76503369acf975bae212bf1cffae27e96186ac') ;;
  *) echo "FAIL: FRANKENPHP_IMAGE is not a reviewed image digest: $selected" >&2; exit 1 ;;
esac
# shellcheck disable=SC2016 # Dockerfile variable reference is literal.
expected_stages='FROM composer:2 AS composer-bin
FROM ${FRANKENPHP_IMAGE}'
stages="$(awk 'toupper($1) == "FROM" { print }' "$root/Dockerfile")"
if [ "$stages" != "$expected_stages" ] ||
   [ "$(awk 'toupper($1) == "ARG" && $2 ~ /^FRANKENPHP_IMAGE([=]|$)/ { count++ } END { print count+0 }' "$root/Dockerfile")" -ne 1 ] ||
   ! grep -Fxq "ARG FRANKENPHP_IMAGE=$reviewed" "$root/Dockerfile" ||
   ! grep -Fxq "FROM \${FRANKENPHP_IMAGE}" "$root/Dockerfile" ||
   ! grep -Fxq "        FRANKENPHP_IMAGE: \${FRANKENPHP_IMAGE:-$reviewed}" "$root/compose.yml" ||
   grep -q 'FRANKENPHP_IMAGE' "$root/skills/verify-frankenphp-moodle/compose.verify.yml"; then
  echo 'FAIL: Dockerfile or Compose image selection differs from the reviewed policy' >&2
  exit 1
fi
printf 'OK: source defaults and supplied shell override match reviewed policy: %s\n' "$selected"
