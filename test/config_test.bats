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
  run $YACT -a config set hide_done 1

  # then
  run $YACT
  assert_output -p "2 [  ] task 2"
  refute_output -p "1 [  ] task 1"
  assert_output -p "Main list for testing - (1/2)"
}

@test "config - set show done" {
  # given
  run $YACT -a config set hide_done 1
  run $YACT add "task 1"
  run $YACT add "task 2"
  run $YACT done 1

  # when
  run $YACT -a config set hide_done 0

  # then
  run $YACT
  assert_output -p "2 [  ] task 2"
  assert_output -p "1 [ok] task 1"
}

@test "config list - show all config options (pretty)" {
  # when
  run $YACT -a config

  # then
  assert_output -p "use_formatting  --  Turns formatting on or off"
  assert_output -p "hide_done       --  If set done tasks won't be shown"
  assert_output -p "line_length     --  Maximum line length before wrapping text"
  assert_output -p \
    "insert_top      --  If set new tasks will be inserted to the top of the list"
}

@test "config list - show all config options (simple)" {
  # when
  run $YACT -a config -c

  # then
  assert_output -p "use_formatting:Turns formatting on or off"
  assert_output -p "hide_done:If set done tasks won't be shown"
  assert_output -p "line_length:Maximum line length before wrapping text"
}

@test "config unset - reset hide_done" {
  # given
  run $YACT -a config set hide_done 1
  run $YACT add "task 1"
  run $YACT add "task 2"
  run $YACT done 1

  # when
  run $YACT -a config unset hide_done

  # then
  run $YACT
  assert_output -p "2 [  ] task 2"
  assert_output -p "1 [ok] task 1"
}

@test "config get - shows value" {
 # given
 run $YACT -a config set hide_done 1

 # when
 run $YACT -a config get hide_done

 # then
 assert_output -p "name:         hide_done"
 assert_output -p "description:  If set done tasks won't be shown"
 assert_output -p "value:        1"
}

