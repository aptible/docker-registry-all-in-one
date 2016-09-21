#!/usr/bin/env bats

. "${BATS_TEST_DIRNAME}/test_helper.sh"

setup() {
  do_minimal_setup
}

@test "docker-registry-proxy configures a v2 registry" {
  export AUTH_CREDENTIALS=foobar:password
  run timeout 5 docker-registry-proxy-bootstrap
  [[ "$status" -eq "$TIMEOUT_STATUS" ]]

  grep "listen.*default" "/etc/nginx/registry-v2.conf"
  grep "server_name example.com" "/etc/nginx/registry-v2.conf"

  run grep "listen.*default" "/etc/nginx/registry-v1.conf"
  [[ "$status" == "1" ]]
  run grep "server_name example.com" "/etc/nginx/registry-v1.conf"
  [[ "$status" == "1" ]]
}

