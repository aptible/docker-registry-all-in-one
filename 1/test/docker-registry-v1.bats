#!/usr/bin/env bats

. "${BATS_TEST_DIRNAME}/test_helper.sh"

setup() {
  do_full_setup
}

@test "docker-registry runs a v1 Docker registry" {
  run curl -k "https://${AUTH_CREDENTIALS}@127.0.0.1:443/v1/repositories/aptible/alpine/tags/latest"
  echo "$output"
  [[ "$output" =~ "Tag not found" ]]
}
