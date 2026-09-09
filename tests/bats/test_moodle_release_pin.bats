#!/usr/bin/env bats

@test "Docker build defaults pin Moodle 5.2.2 from stable502" {
  run grep -Fx "ARG MOODLE_SERIES=stable502" Dockerfile
  [ "${status}" -eq 0 ]

  run grep -Fx "ARG MOODLE_VERSION=5.2.2" Dockerfile
  [ "${status}" -eq 0 ]

  run grep -F "https://download.moodle.org/download.php/direct/\${MOODLE_SERIES}/moodle-\${MOODLE_VERSION}.tgz" Dockerfile
  [ "${status}" -eq 0 ]
}

@test "Compose build args default to Moodle 5.2.2 from stable502" {
  run grep -Fx "        MOODLE_SERIES: \${MOODLE_SERIES:-stable502}" compose.yml
  [ "${status}" -eq 0 ]

  run grep -Fx "        MOODLE_VERSION: \${MOODLE_VERSION:-5.2.2}" compose.yml
  [ "${status}" -eq 0 ]
}

@test "Dockerfile supports both Moodle web-root layouts" {
  run grep -F 'if [ -d /app/public/public ]; then' Dockerfile
  [ "${status}" -eq 0 ]

  run grep -F 'root * {$MOODLE_WEB_ROOT:/app/public/public}' docker/Caddyfile
  [ "${status}" -eq 0 ]

  run grep -F 'MOODLE_WEB_ROOT="${MOODLE_WEB_ROOT:-}"' docker/entrypoint.sh
  [ "${status}" -eq 0 ]
}

@test "Dockerfile uses the direct Moodle archive path for alternate series" {
  run grep -F 'https://download.moodle.org/download.php/direct/${MOODLE_SERIES}/moodle-${MOODLE_VERSION}.tgz' Dockerfile
  [ "${status}" -eq 0 ]
}
