#!/usr/bin/env bats

. "${BATS_TEST_DIRNAME}/test_helper.sh"

setup() {
  do_full_setup
}

@test "docker-registry exposes a single process on 0.0.0.0: nginx" {
  # Nginx should be running here.
  run bash -c 'netstat -ntpl | grep "0.0.0.0" | grep -i "nginx" | wc -l'
  echo "$output"
  [[ "$output" -eq 1 ]]

  # Here, we should have registry v1, registry v2, and Redis.
  run bash -c 'netstat -ntpl | grep "127.0.0.1" | wc -l'
  echo "$output"
  [[ "$output" -eq 3 ]]
}
