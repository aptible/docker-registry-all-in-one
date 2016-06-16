#!/usr/bin/env bats

. "${BATS_TEST_DIRNAME}/test_helper.sh"

setup() {
  do_minimal_setup
}

@test "docker-registry-proxy configures a v1 registry" {
  export AUTH_CREDENTIALS=foobar:password
  run timeout 5 docker-registry-proxy
  [[ "$status" -eq "$TIMEOUT_STATUS" ]]
  run bash -c "ls /etc/nginx/sites-enabled | wc -l"
  [[ "$output" == "1" ]]
  run cat /etc/nginx/sites-enabled/proxy.conf
  [[ "$output" =~ "location /v1" ]]
  [[ ! "$output" =~ "location /v2" ]]
}

