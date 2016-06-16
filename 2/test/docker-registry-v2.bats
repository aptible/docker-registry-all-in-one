#!/usr/bin/env bats

. "${BATS_TEST_DIRNAME}/test_helper.sh"

setup() {
  do_full_setup
}

@test "docker-registry runs a v2 Docker registry" {
  run curl -k "https://${AUTH_CREDENTIALS}@127.0.0.1:443/v2/aptible/alpine/manifests/latest"
  echo "OUT $output"
  [[ "$output" =~ "MANIFEST_UNKNOWN" ]]
}
