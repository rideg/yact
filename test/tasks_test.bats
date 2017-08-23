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

################################################################################
################################## SHOW ########################################
################################################################################

@test "task show - shows message for empty list" {
    # when
    run $YACT
    # then
    assert_output -p 'Main list for testing - (0/0)'
    assert_output -p 'There are now tasks defined yet.'
}

@test "task show - hides done tasks if HIDE_DONE is set" {
    # given
    run $YACT add "This is a task1"
    run $YACT add "This is a task2"
    run $YACT add "This is a task3"
    run $YACT done 2
    echo 'HIDE_DONE=1' >> "$YACT_DIR/config"
    # when
    run $YACT
    # then
    assert_output -p 'Main list for testing - (1/3)'
    assert_output -p '1 [  ] This is a task1'
    refute_output -p '2 [  ] This is a task2'
    assert_output -p '3 [  ] This is a task3'
}

################################################################################
################################## ADD #########################################
################################################################################

@test "task add - new item" {
    # when
    run $YACT add "A new task for test"
    # then
    assert_output -p 'Main list for testing - (0/1)'
    assert_output -p '1 [  ] A new task for test'
}

@test "task add - uses editor if no description is provided" {
    # given
    _spy_tool nano 'echo "The new description" > $1'
    # when
    run $YACT add
    # then
    assert_output -p '1 [  ] The new description'
}

@test "task add - inserts to a specified position" {
    # given
    run $YACT add "This is a task1"
    run $YACT add "This is a task2"
    # when
    run $YACT add -p 2 "This is a task3"
    # then
    assert_output -p '1 [  ] This is a task1'
    assert_output -p '2 [  ] This is a task3'
    assert_output -p '3 [  ] This is a task2'
}

@test "task add - inserts to the top" {
    # given
    run $YACT add "This is a task1"
    run $YACT add "This is a task2"
    # when
    run $YACT add -p top "This is a task3"
    # then
    assert_output -p '1 [  ] This is a task3'
    assert_output -p '2 [  ] This is a task1'
    assert_output -p '3 [  ] This is a task2'
}

@test "task add - should replace new lines with spaces" {
    # when
    run $YACT add $'task1\nand something'
    # then
    assert_output -p '1 [  ] task1 and something'
}

@test "task add - inserts to the top when set" {
    # given
    run $YACT -a config set insert_top 1

    # when
    run $YACT add "task 1"
    run $YACT add "task 2"
    run $YACT add "task 3"

    # then
    assert_output -p '1 [  ] task 3'
    assert_output -p '2 [  ] task 2'
    assert_output -p '3 [  ] task 1'
}

################################################################################
################################## DONE ########################################
################################################################################

@test "task done - marks item as done" {
    # given
    run $YACT add "A new task for test"
    # when
    run $YACT done 1
    # then
    assert_output -p 'Main list for testing - (1/1)'
    assert_output -p '1 [ok] A new task for test'
}

################################################################################
################################## UNDONE ######################################
################################################################################

@test "task undone - marks done item as not done" {
    # given
    run $YACT add "A new task for test"
    run $YACT done 1
    # when
    run $YACT undone 1
    # then
    assert_output -p 'Main list for testing - (0/1)'
    assert_output -p '1 [  ] A new task for test'
}

################################################################################
################################## DELETE ######################################
################################################################################

@test "task delete - deletes from list" {
    # given
    run $YACT add "A new task for test"
    run $YACT add "A new task for test2"
    run $YACT add "A new task for test3"
    # when
    run $YACT delete 2 < <(echo y)
    # then
    assert_output -p 'Task: "A new task for test2"'
    assert_output -p 'Are you sure you want to delete? y/[n]'
    assert_output -p 'Main list for testing - (0/2)'
    assert_output -p '1 [  ] A new task for test'
    assert_output -p '2 [  ] A new task for test3'
    refute_output -p '[  ] A new task for test2'
}

@test "task delete - keeps task if consent is not given" {
    # given
    run $YACT add "A new task for test3"
    # when
    run $YACT delete 1 < <(echo n)
    # then
    assert_output -p 'Are you sure you want to delete? y/[n]'
    assert_output -p 'Main list for testing - (0/1)'
    assert_output -p '1 [  ] A new task for test3'
}

@test "task delete - should delete multiple tasks" {
   # given
   run $YACT add "task1"
   run $YACT add "task2"
   run $YACT add "task3"
   run $YACT add "task4"
   # when
   run $YACT delete 2 3 < <(echo "yy")
   # then
   assert_output -p "1 [  ] task1"
   refute_output -p "2 [  ] task2"
   refute_output -p "3 [  ] task3"
   assert_output -p "2 [  ] task4"
}

@test "task delete - should not ask for consent if -f is given" {
  # given
  run $YACT add "task1"
  run $YACT add "task2"
  # when
  run $YACT delete -f 2
  # then
  refute_output -p 'Are you sure you want to delete? y/[n]'
  assert_output -p '1 [  ] task1'
  refute_output -p '2 [  ] task2'
}

@test "task delete - should delete with start-end notation" {
  # given
  run $YACT add "task 1"
  run $YACT add "task 2"
  run $YACT add "task 3"
  run $YACT add "task 4"
  run $YACT add "task 5"

  # when
  run $YACT delete -f 2-5

  # then
  assert_output -p '1 [  ] task 1'
  assert_output -p '2 [  ] task 5'
  refute_output -p '3 [  ] '
}

@test "task delete - should delete with start-end notation (reverse)" {
  # given
  run $YACT add "task 1"
  run $YACT add "task 2"
  run $YACT add "task 3"
  run $YACT add "task 4"
  run $YACT add "task 5"

  # when
  run $YACT delete -f 5-2

  # then
  assert_output -p '1 [  ] task 1'
  assert_output -p '2 [  ] task 5'
  refute_output -p '3 [  ] '
}

@test "task delete - should delete with start.. notation" {
  # given
  run $YACT add "task 1"
  run $YACT add "task 2"
  run $YACT add "task 3"
  run $YACT add "task 4"
  run $YACT add "task 5"

  # when
  run $YACT delete -f 2..

  # then
  assert_output -p '1 [  ] task 1'
  refute_output -p '2 [  ] '
}

@test "task delete - should delete with ..end notation" {
  # given
  run $YACT add "task 1"
  run $YACT add "task 2"
  run $YACT add "task 3"
  run $YACT add "task 4"
  run $YACT add "task 5"

  # when
  run $YACT delete -f ..3

  # then
  assert_output -p '1 [  ] task 3'
  assert_output -p '2 [  ] task 4'
  assert_output -p '3 [  ] task 5'
  refute_output -p '4 [  ] '
}

################################################################################
################################## MODIFY ######################################
################################################################################

@test "task modify - changes item description" {
    # given
    run $YACT add "A new task for test"
    # when
    run $YACT modify 1 "This is a modified item"
    # then
    assert_output -p '1 [  ] This is a modified item'
}

@test "task modify - description (interactive)" {
    # given
    _spy_tool nano 'echo "The new description" > $1'

    run $YACT add "A new task for test"
    # when
    run $YACT modify 1
    # then
    assert_output -p '1 [  ] The new description'
}

@test "task modify - using special charactes" {
    # given
    run $YACT add "This is task"
    # when
    run $YACT modify 1 "The new task description: ( \ / ) { } [ ] &"
    # then
    assert_output -p '1 [  ] The new task description: ( \ / ) { } [ ] &'
}

################################################################################
#################################### MOVE ######################################
################################################################################

__create_three_tasks() {
    run $YACT add "First task"
    run $YACT add "Second task"
    run $YACT add "Third task"
}

@test "task move - swaps second and third" {
    # given
    __create_three_tasks
    # when
    run $YACT move 2 3
    # then
    assert_line -n 3 -p '3 [  ] Second task'
    assert_line -n 2 -p '2 [  ] Third task'
}

@test "task move - swaps first and second" {
    # given
    __create_three_tasks
    # when
    run $YACT move 1 2
    # then
    assert_line -n 1 -p '1 [  ] Second task'
    assert_line -n 2 -p '2 [  ] First task'
}

@test "task move - keeps the original order if position and id equals" {
    # given
    __create_three_tasks
    # when
    run $YACT move 1 1
    # then
    assert_line -n 1 -p '1 [  ] First task'
}

@test "task move - puts item to the top of the list" {
    # given
    __create_three_tasks
    # when
    run $YACT move 3 top
    # then
    assert_line -n 1 -p '1 [  ] Third task'
}

@test "task move - puts item to the bottom of the list" {
    # given
    __create_three_tasks
    # when
    run $YACT move 1 bottom
    # then
    assert_line -n 3 -p '3 [  ] First task'
}

@test "task move - swaps item with item above" {
    # given
    __create_three_tasks
    # when
    run $YACT move 2 up
    # then
    assert_line -n 1 -p '1 [  ] Second task'
    assert_line -n 2 -p '2 [  ] First task'
}

@test "task move - swaps item with item below" {
    # given
    __create_three_tasks
    # when
    run $YACT move 2 down
    # then
    assert_line -n 2 -p '2 [  ] Third task'
    assert_line -n 3 -p '3 [  ] Second task'
}

@test "task move - doesn't change list if up first item" {
    # given
    __create_three_tasks
    # when
    run $YACT move 1 up
    # then
    assert_line -n 1 -p '1 [  ] First task'
}

@test "task move - doesn't change list if top first item" {
    # given
    __create_three_tasks
    # when
    run $YACT move 1 top
    # then
    assert_line -n 1 -p '1 [  ] First task'
}

@test "task move - doesn't change list if down last item" {
    # given
    __create_three_tasks
    # when
    run $YACT move 3 down
    # then
    assert_line -n 3 -p '3 [  ] Third task'
}

@test "task move - doesn't change list if bottom last item" {
    # given
    __create_three_tasks
    # when
    run $YACT move 3 bottom
    # then
    assert_line -n 3 -p '3 [  ] Third task'
}

################################################################################
#################################### SWAP ######################################
################################################################################

@test "task swap - should swap two tasks" {
  # given
  run $YACT add "task1"
  run $YACT add "task2"
  run $YACT add "task3"

  # when
  run $YACT swap 1 3

  # then
  run $YACT
  assert_output -p "1 [  ] task3"
  assert_output -p "2 [  ] task2"
  assert_output -p "3 [  ] task1"
}

################################################################################
################################## REVERSE #####################################
################################################################################

@test "task reverse - reverses the task order" {
  # given
  run $YACT add "task1"
  run $YACT add "task2"
  run $YACT add "task3"
  run $YACT add "task4"

  # when
  run $YACT reverse

  # then
  assert_output -p "1 [  ] task4"
  assert_output -p "2 [  ] task3"
  assert_output -p "3 [  ] task2"
  assert_output -p "4 [  ] task1"
}

