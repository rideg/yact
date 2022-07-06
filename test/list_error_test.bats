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
  assert_output 'Please provide a position'
}

@test "switch - error for unknonw list id" {
  # when
  run $YACT -l switch kklsfa
  # then
  assert_output 'The given position is not numeric [kklsfa]'
}

@test "modify - error for no list id" {
 # when
 run $YACT -l modify
 # then
 assert_output 'Please provide a position'
}

@test "modify - error for non-existing list id is provided" {
 # when
 run $YACT -l modify dsfsadv
 # then
 assert_output "The given position is not numeric [dsfsadv]"
}

@test "delete - error if non existing list id is given" {
  # when
  run $YACT -l delete non-existing
  # then
  assert_output "The given position is not numeric [non-existing]"
} 

