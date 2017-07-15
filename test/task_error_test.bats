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

@test "task move error - non-numeric id is provided" {
	# when
	run $YACT move hhklj 1
	# then
	assert_failure
	assert_output -p "The provided id is not numeric [hhklj]"
}

@test "task move error - non-numeric position is provided" {
	# when
	run $YACT add "First task"
	run $YACT move 1 hhklj
	# then
	assert_failure
	assert_output -p "The given position is not numeric [hhklj]"
}

@test "task move error - non-existing id is provided" {
	# when
	run $YACT move 1 3
	# then
	assert_failure
	assert_output -p "Out of range task position [1]"
}

@test "task move error - non-existing position is provided" {
	# when
	run $YACT add "Test task 1"
	run $YACT move 1 3
	# then
	assert_failure
	assert_output -p "Out of range task position [3]"
}

@test "task new error - interactive mode with empty tmp file" {
  # given
  _spy_tool nano ':' 
  # when
  run $YACT add 
  # then
  assert_output -p $'Please provide description.'
}

@test "task delete error - one id is incorrect" {
  # given
  run $YACT add "task1"
  run $YACT add "task2"
  run $YACT add "task3"
  run $YACT add "task4"
  # when
  run $YACT delete 2 bela < <(echo y)
  # then
  assert_output -p "The given position is not numeric [bela]"
}

