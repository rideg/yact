#!/usr/bin/env bats

load 'load'
load 'helper'

setup() {
  _setup_yact
  _set_no_color
}

teardown() {
  _clean_test_dir
  _clean_patch_dir
}

@test "migration - no need for it" {
  run $YACT migrate 

  assert_output -p  "Storage is up to date."
}

@test "migration - executes patches" {
 _create_patch 1 "printf 'patch 0001\n'"
 _create_patch 2 "printf 'patch 0002\n'"
 _create_patch 3 "printf 'patch 0003\n'"

 run $YACT migrate

 assert_output -p 'Storage migration is needed.'
 assert_output -p 'Current storage version is: 0.'
 assert_output -p 'Desired version is: 3'
 assert_output -p 'patch 0001'
 assert_output -p 'patch 0002'
 assert_output -p 'patch 0003'
}
