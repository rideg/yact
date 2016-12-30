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

@test "Show message if there is no list defined" {
  # when
  run $YACT -l
  # then
  assert_output 'No todo list has been selected, please select/create one.'
}

@test "Create a new list" {
  # when
  run $YACT -l new This is a list.
  # then
  assert_output -p $' * 1234123\tThis is a list. (0/0)'
}

@test "Create two lists" {
  # given
  run $YACT -l new This is a list.
  # when
  run $YACT -l new This is a list2.
  # then
  assert_output -p $' 1234123\tThis is a list. (0/0)'
  assert_output -p $' * 1234124\tThis is a list2. (0/0)'
}

@test "Set the actual list after deletion" {
  # given
  run $YACT -l new This is a list.
  run $YACT -l new This is a list2.
  # when
  run $YACT -l delete 1234124
  # then
  assert_output -p $' * 1234123\tThis is a list. (0/0)'
}

@test "Show message after deleting the last list" {
  # given
  run $YACT -l new This is a list.
  # when
  run $YACT -l delete 1234123
  # then
  assert_success
}

@test "Switch to other list" {
  # given
  run $YACT -l new This is a list.
  run $YACT -l new This is a list2.
  #when
  run $YACT -l switch 1234123
  # then
  assert_output -p $' * 1234123\tThis is a list. (0/0)'
  assert_output -p $' 1234124\tThis is a list2. (0/0)'
}

@test "Update list information based on the task" {
  # given 
  run $YACT -l new This is a list.
  run $YACT new this is a task
  run $YACT new this is a task2
  run $YACT done 1
  # when
  run $YACT -l
  # then
  assert_output -p $' * 1234123\tThis is a list. (1/2)'
}

@test "Modify list description" {
  # given
  run $YACT -l new "This is a list."
  # when
  run $YACT -l modify 1234123 "The new description."
  # then
  assert_output -p $' * 1234123\tThe new description. (0/0)'
}

@test "Modify list description (interactive)" {
  # given
  export EDITOR=nano
  _spy_tool nano 'echo "The new description" > $1' 
  run $YACT -l new "This is a list."
  # when
  run $YACT -l modify 1234123 "The new description."
  # then
  assert_output -p $' * 1234123\tThe new description. (0/0)'
}

@test "Create new list interactive" {
  # given
  export EDITOR=nano
  _spy_tool nano 'echo "The new description." > $1' 
  # when
  run $YACT -l new 
  # then
  assert_output -p $' * 1234123\tThe new description. (0/0)'
}

