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

@test "config set - error when unknown config value is given" {
  # when
  run $YACT -a config set non-existing 1

  # then
  assert_output -p "No option with name: non-existing"
}

@test "config set - error when wrong type is given (boolean)" {
  # when
  run $YACT -a config set hide_done hello

  # then
  assert_output -p "The given value: 'hello' is not a boolean."
}

@test "config set - error when wrong type is given (integer)" {
  # when
  run $YACT -a config set line_length -35

  # then
  assert_output -p "The given value: '-35' is not a positive number."
}

@test "config - unknown command" {
  # when
  run $YACT -a config unknown

  # then
  assert_output -p "Unknown command: unknown"
}
