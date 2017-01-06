#!/usr/bin/env bats

load 'load'
load 'helper'

setup() {
  _setup_yact
  _set_no_color
  run $YACT -l new "Main list for testing" 
}

teardown() {
  _clean_test_dir
}

@test "config - set hide done" {
  # given
  run $YACT add "task 1"
  run $YACT add "task 2"
  run $YACT done 1
  # when
  run $YACT config hide_done=1
  # then
  assert_output -p "2 [  ] task 2"
  refute_output -p "1 [  ] taks 1"
  assert_output -p "Main list for testing - (1/2)"
}

@test "config - set show done" {
  # given
  run $YACT config hide_done=1
  run $YACT add "task 1"
  run $YACT add "task 2"
  run $YACT done 1
  # when
  run $YACT config hide_done=0
  # then
  assert_output -p "2 [  ] task 2"
  assert_output -p "1 [ok] task 1"
}

