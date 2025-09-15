#!/usr/bin/env bats

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

function setup() {
    targetdir="./src/spai.sh"
}

@test "script shows version" {
  run $targetdir version
  assert_success
  assert_output "SPAI CLI v1.0.2"
}
