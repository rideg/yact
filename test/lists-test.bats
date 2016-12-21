#!/usr/bin/env bats

load 'load'
load 'helper'

setup() {
  _setup_yact
  _set_no_color
  _spy_tool date "printf '1234123'"
}

teardown() {
  _clean_test_dir
}

@test "Should show message if there is not list defined" {
    # when
    run $YACT -l
    # then
    assert_output "No todo list has been selected, please select/create one."
}

@test "It should create a new list" {
    # when
    run $YACT -l new This is a list.
    # then
    assert_output --partial $(printf ' * 1234123\tThis is a list. (0/0)')
}

@test "It should create two lists" {
    # given
    run $YACT -l new This is a list.
    # when
    run $YACT -l new This is a list2.
    # then
    assert_output --partial $(printf ' 1234123\tThis is a list. (0/0)')
    assert_output --partial $(printf ' * 1234124\tThis is a list2. (0/0)')
}

@test "It should set the actual list after deletion" {
    # given
    run $YACT -l new This is a list.
    run $YACT -l new This is a list2.
    # when
    run $YACT -l delete 1234124
    # then
    assert_output --partial $(printf ' * 1234123\tThis is a list. (0/0)')
}

@test "It should show message after deleting the last list" {
    # given
    run $YACT -l new This is a list.
    # when
    run $YACT -l delete 1234123
    # then
    assert_success
}

@test "It should switch other list" {
    # given
    run $YACT -l new This is a list.
    run $YACT -l new This is a list2.
    #when
    run $YACT -l switch 1234123
    # then
    assert_output --partial $(printf ' * 1234123\tThis is a list. (0/0)')
    assert_output --partial $(printf ' 1234124\tThis is a list2. (0/0)')
}

@test "It should update list information based on the task" {
    # given 
    run $YACT -l new This is a list.
    run $YACT new this is a task
    run $YACT new this is a task2
    run $YACT done 1
    # when
    run $YACT -l
    # then
    assert_output --partial $(printf ' * 1234123\tThis is a list. (1/2)')
}
