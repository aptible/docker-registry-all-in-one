#!/usr/bin/env bats

. "${BATS_TEST_DIRNAME}/test_helper.sh"

setup() {
  do_minimal_setup
}

@test "docker-registry-proxy-bootstrap uses an nginx version >= 1.7.5" {
  # We need at least 1.7.5 for built-in handling of chunked transfer encoding (1.3.9)
  # and support for the "always" parameter in the "add_header" directive (1.7.5).
  version="$(/usr/sbin/nginx -v 2>&1 | grep -oE '[0-9]\.[0-9]+\.[0-9]+')"
  dpkg --compare-versions "$version" "ge" "1.7.5"
}

@test "docker-registry-proxy-bootstrap requires the AUTH_CREDENTIALS environment variable to be set" {
  run timeout 10 docker-registry-proxy-bootstrap
  echo "$output" # Will be silenced by bats unless the test fails
  [[ "$status" -eq 1 ]]
  [[ "$output" =~ "AUTH_CREDENTIALS should be populated" ]]
}

@test "docker-registry-proxy-bootstrap requires a key in /etc/nginx/ssl" {
  export AUTH_CREDENTIALS=foobar:password
  rm /etc/nginx/ssl/docker-registry-proxy.key
  run timeout 10 docker-registry-proxy-bootstrap
  echo "$output"
  [[ "$status" -eq 1 ]]
  [[ "$output" =~ "No key file" ]]
}

@test "docker-registry-proxy-bootstrap returns an error if more than one key is provided" {
  export AUTH_CREDENTIALS=foobar:password
  touch /etc/nginx/ssl/extra-key.key
  run timeout 10 docker-registry-proxy-bootstrap
  echo "$output"
  [[ "$status" -eq 1 ]]
  [[ "$output" =~ "Multiple key files" ]]
}

@test "docker-registry-proxy-bootstrap requires a certificate in /etc/nginx/ssl" {
  export AUTH_CREDENTIALS=foobar:password
  rm /etc/nginx/ssl/docker-registry-proxy.crt
  run timeout 10 docker-registry-proxy-bootstrap
  echo "$output"
  [[ "$status" -eq 1 ]]
  [[ "$output" =~ "No certificate file" ]]
}

@test "docker-registry-proxy-bootstrap returns an error if more than one certificate is provided" {
  export AUTH_CREDENTIALS=foobar:password
  touch /etc/nginx/ssl/extra-cert.crt
  run timeout 10 docker-registry-proxy-bootstrap
  echo "$output"
  [[ "$status" -eq 1 ]]
  [[ "$output" =~ "Multiple certificate files" ]]
}
