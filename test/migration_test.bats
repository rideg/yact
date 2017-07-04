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

