#!/usr/bin/env bats

load 'load'
load 'helper'

TIME=1234123

setup() {
  _setup_yact
  _set_no_color
  _spy_tool date "printf '$TIME'"
  ((TIME++))
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
  run $YACT -l
  assert_output -p $'1 This is a list. (0/0) *'
}

@test "Create two lists" {
  # given
  run $YACT -l new This is a list.
  # when
  run $YACT -l new This is a list2.
  # then
  run $YACT -l
  assert_output -p '1 This is a list. (0/0)'
  assert_output -p '2 This is a list2. (0/0) *'
}

@test "Set the actual list after deletion" {
  # given
  run $YACT -l new This is a list.
  run $YACT -l new This is a list2.
  # when
  run $YACT -l delete 2 < <(echo y)
  # then
  run $YACT -l
  assert_output -p '1 This is a list. (0/0) *'
}

@test "Show message after deleting the last list" {
  # given
  run $YACT -l new This is a list.
  # when
  run $YACT -l delete 1 < <(echo y)
  # then
  assert_output -p 'List name: This is a list.'
  assert_success
}

@test "Do not delete if consent is not given" {
  # given
  run $YACT -l new This is a list.
  run $YACT -l new This is a list2.
  # when
  run $YACT -l delete 2 < <(echo n)
  # then
  run $YACT -l
  assert_output -p '2 This is a list2. (0/0) *'
}

@test "Switch to other list" {
  # given
  run $YACT -l new This is a list.
  run $YACT -l new This is a list2.
  #when
  run $YACT -l switch 1
  # then
  run $YACT -l
  assert_output -p '1 This is a list. (0/0) *'
  assert_output -p '2 This is a list2. (0/0)'
}

@test "Update list information based on the task" {
  # given
  run $YACT -l new This is a list.
  run $YACT add this is a task
  run $YACT add this is a task2
  run $YACT done 1
  run $YACT add -s separator
  # when
  run $YACT -l
  # then
  assert_output -p '1 This is a list. (1/2) *'
}

@test "Modify list description" {
  # given
  run $YACT -l new "This is a list."
  # when
  run $YACT -l modify 1 "The new description."
  # then
  run $YACT -l
  assert_output -p '1 The new description. (0/0) *'
}

@test "Modify list description (interactive)" {
  # given
  _spy_tool nano 'echo "The new description" > $1'
  run $YACT -l new "This is a list."
  # when
  run $YACT -l modify 1 "The new description."
  # then
  run $YACT -l
  assert_output -p '1 The new description. (0/0) *'
}

@test "Create new list interactive" {
  # given
  _spy_tool nano 'echo "The new description." > $1'
  # when
  run $YACT -l new
  # then
  run $YACT -l
  assert_output -p '1 The new description. (0/0) *'
}

@test "Should show tasks from list after switchig to a different list" {
  # given
  run $YACT -l new "Initial list"
  run $YACT add "Task 1"
  run $YACT -l new "Other list"
  # when
  run $YACT -l switch 1
  # then
  assert_output -p '1 [  ] Task 1'
}

