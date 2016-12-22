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

@test "move - shows error message if non-numeric id is provided" {
	# when
	run $YACT move hhklj 1
	# then
	assert_failure
	assert_output -p "The provided id is not numberic [hhklj]"
}

@test "move - shows error if non-numeric position is provided" {
	# when
	run $YACT move 1 hhklj
	# then
	assert_failure
	assert_output -p "The provided position is not numberic [hhklj]"
}

@test "move - shows error if non-existing id is provided" {
	# when
	run $YACT move 1 3
	# then
	assert_failure
	assert_output -p "There is no task with the provided id [1]"
}

@test "move - shows error if non-existing position is provided" {
	# when
	run $YACT new "Test task 1"
	run $YACT move 1 3
	# then
	assert_failure
	assert_output -p "Non existing position [3]"
}
