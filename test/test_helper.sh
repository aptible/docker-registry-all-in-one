#!/bin/bash

export TIMEOUT_STATUS=124

do_minimal_setup() {
  mkdir -p /etc/nginx/ssl
  openssl req -x509 -batch -nodes -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/docker-registry-proxy.key \
    -out /etc/nginx/ssl/docker-registry-proxy.crt

  export SERVER_NAME="example.com"
}

do_full_setup() {
  do_minimal_setup
  export AUTH_CREDENTIALS=foobar:password

  supervisord -c /etc/supervisord.conf &
  SUPERVISOR_PID=$!

  # Give all services 20 seconds to come up
  for _ in $(seq 1 20); do
    sleep 1
    echo "$(date) Waiting for services to come up..."
    nc -z 127.0.0.1 443 || continue  # Nginx
    nc -z 127.0.0.1 5000 || continue # Registry
    nc -z 127.0.0.1 6379 || continue # Redis cache
    break
  done
}

teardown() {
  local pid="${SUPERVISOR_PID:-NOT_SET}"
  if [[ "$pid" != NOT_SET ]]; then
    kill -TERM "$SUPERVISOR_PID"
    wait "$SUPERVISOR_PID"
    unset SUPERVISOR_PID
  fi

  local creds="${AUTH_CREDENTIALS:-NOT_SET}"
  if [[ "$creds" != NOT_SET ]]; then
    unset AUTH_CREDENTIALS
  fi

  rm /etc/nginx/conf.d/docker-registry-proxy.htpasswd || true
  rm /etc/nginx/nginx.conf || true
  rm /etc/nginx/registry-v1.conf || true
  rm /etc/nginx/registry-v2.conf || true
  rm -f /etc/nginx/ssl/* || true
  rm -f /var/log/nginx/* || true
  rm -f /var/run/nginx/* || true
}
