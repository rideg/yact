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

@test "Should show message for empty list" {
    # when
    run $YACT
    # then
    assert_output --partial "Main list for testing - (0/0)"
    assert_output --partial "There are now tasks defined yet."
}

@test "Should add new item to the list" {
    # when
    run $YACT new "A new task for test"
    # then
    assert_output --partial "Main list for testing - (0/1)"
    assert_output --partial "1 [  ] A new task for test"
}

@test "Should mark item as done" {
    # given
    run $YACT new "A new task for test"
    # when
    run $YACT done 1
    # then
    assert_output --partial "Main list for testing - (1/1)"
    assert_output --partial "1 [ok] A new task for test"
}

@test "Should mark done item as not done" {
    # given
    run $YACT new "A new task for test"
    run $YACT done 1
    # when
    run $YACT undone 1
    # then
    assert_output --partial "Main list for testing - (0/1)"
    assert_output --partial "1 [  ] A new task for test"
}

@test "Should delete from list" {
    # given
    run $YACT new "A new task for test"
    run $YACT new "A new task for test2"
    run $YACT new "A new task for test3"
    # when
    run $YACT delete 2
    # then
    assert_output --partial "Main list for testing - (0/2)"
    assert_output --partial "1 [  ] A new task for test"
    assert_output --partial "2 [  ] A new task for test3"
    refute_output --partial "A new task for test2"
}

@test "Should modify item description" {
    # given
    run $YACT new "A new task for test"
    # when
    run $YACT modify 1 "This is a modified item"
    # then
    assert_output --partial "1 [  ] This is a modified item"
}

@test "Should modify item description (interactive)" {
    # given
    export EDITOR=nano
    _spy_tool nano 'echo "The new description" > $1'

     run $YACT new "A new task for test"
     # when
     run $YACT modify 1
     #then
     assert_output --partial "1 [  ] The new description"
}