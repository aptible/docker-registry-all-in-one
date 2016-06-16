#!/usr/bin/env bats

. "${BATS_TEST_DIRNAME}/test_helper.sh"

setup() {
  do_full_setup
}

@test "docker-registry exposes a single process on 0.0.0.0: nginx" {
  run bash -c 'netstat -ntpl | grep "0.0.0.0" | grep -i "nginx" | wc -l'
  [[ "$output" -eq 1 ]]

  run bash -c 'netstat -ntpl | grep "127.0.0.1" | wc -l'
  [[ "$output" -eq 2 ]]
}
