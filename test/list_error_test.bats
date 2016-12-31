#!/usr/bin/env bats

load 'load'
load 'helper'

setup() {
  _setup_yact
  _set_no_color
  _spy_tool date "printf '1234123'"
  run $YACT -l new "Test todo"
}

teardown() {
  _clean_test_dir
}

@test "switch - error for no list id" {
  # when
  run $YACT -l switch
  # then
  assert_output 'Missing list id, please provide it.'
}

@test "switch - error for unknonw list id" {
  # when
  run $YACT -l switch kklsfa
  # then
  assert_output 'Non-existing list id kklsfa'
}

@test "modify - error for no list id" {
 # when
 run $YACT -l modify
 # then
 assert_output 'Please provide an id.'
}

@test "modify - error for non-existing list id is provided" {
 # when
 run $YACT -l modify dsfsadv
 # then
 assert_output "Non-existing file. $YACT_DIR/_dsfsadv.txt"
}

@test "modify - error if cannot update file" {
  # given
  local list_file="$YACT_DIR/_1234123.txt"
  _spy_tool nano "rm -f $list_file; echo \"The new description\" > \$1" 
  # when
  run $YACT -l modify 1234123
  # then
  assert_output "Could not update file: $list_file"
}

