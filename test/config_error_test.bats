#!/usr/bin/env bats

load 'load'
load 'helper'

setup() {
  _setup_yact
  _set_no_color
}

teardown() {
  _clean_test_dir
}

@test "config - error when unknown config value is given" {
  # when 
  run $YACT -a config non-existing=1

  # then
  assert_output -p "No option with name: non-existing"
}

@test "config - error when wrong type is given (boolean)" {
  # when
  run $YACT -a config hide_done=hello
 
  # then
  assert_output -p "The given value: 'hello' is not a boolean."
}

@test "config - error when wrong type is given (integer)" {
  # when
  run $YACT -a config line_length=-35
 
  # then
  assert_output -p "The given value: '-35' is not a positive number."
}

