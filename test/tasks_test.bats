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
    assert_output -p 'Main list for testing - (0/0)'
    assert_output -p 'There are now tasks defined yet.'
}

@test "Should add new item to the list" {
    # when
    run $YACT add "A new task for test"
    # then
    assert_output -p 'Main list for testing - (0/1)'
    assert_output -p '1 [  ] A new task for test'
}

@test "Should mark item as done" {
    # given
    run $YACT add "A new task for test"
    # when
    run $YACT done 1
    # then
    assert_output -p 'Main list for testing - (1/1)'
    assert_output -p '1 [ok] A new task for test'
}

@test "Should mark done item as not done" {
    # given
    run $YACT add "A new task for test"
    run $YACT done 1
    # when
    run $YACT undone 1
    # then
    assert_output -p 'Main list for testing - (0/1)'
    assert_output -p '1 [  ] A new task for test'
}

@test "Should delete from list" {
    # given
    run $YACT add "A new task for test"
    run $YACT add "A new task for test2"
    run $YACT add "A new task for test3"
    # when
    run $YACT delete 2 < <(echo y)
    # then
    assert_output -p 'Main list for testing - (0/2)'
    assert_output -p '1 [  ] A new task for test'
    assert_output -p '2 [  ] A new task for test3'
    refute_output -p 'A new task for test2'
}

@test "Should keep task if consent is not given" {
    # given
    run $YACT add "A new task for test3"
    # when
    run $YACT delete 1 < <(echo n)
    # then
    assert_output -p 'Are you sure you want to delete? y/[n]'
    assert_output -p 'Main list for testing - (0/1)'
    assert_output -p '1 [  ] A new task for test3'
}

@test "Should modify item description" {
    # given
    run $YACT add "A new task for test"
    # when
    run $YACT modify 1 "This is a modified item"
    # then
    assert_output -p '1 [  ] This is a modified item'
}

@test "Should modify item description (interactive)" {
    # given
    export EDITOR=nano
    _spy_tool nano 'echo "The new description" > $1'

    run $YACT add "A new task for test"
    # when
    run $YACT modify 1
    #then
    assert_output -p '1 [  ] The new description'
}

__create_three_tasks() {
    run $YACT add "First task"
    run $YACT add "Second task"
    run $YACT add "Third task"
}

@test "Should swap second and third" {
    # given
    __create_three_tasks
    # when
    run $YACT move 2 3
    #then
    assert_line -n 3 -p '3 [  ] Second task'
    assert_line -n 2 -p '2 [  ] Third task'
}

@test "Should swap first and second" {
    # given
    __create_three_tasks
    # when
    run $YACT move 1 2
    #then
    assert_line -n 1 -p '1 [  ] Second task'
    assert_line -n 2 -p '2 [  ] First task'
}

@test "Should keep the original order if position and id equals" {
    # given
    __create_three_tasks
    # when
    run $YACT move 1 1
    #then
    assert_line -n 1 -p '1 [  ] First task'
}

@test "move - puts item to the top of the list" {
    # given
    __create_three_tasks
    # when
    run $YACT move 3 top
    #then
    assert_line -n 1 -p '1 [  ] Third task'
}

@test "move - puts item to the bottom of the list" {
    # given
    __create_three_tasks
    # when
    run $YACT move 1 bottom
    #then
    assert_line -n 3 -p '3 [  ] First task'
}

@test "move - swaps item with item above" {
    # given
    __create_three_tasks
    # when
    run $YACT move 2 up
    #then
    assert_line -n 1 -p '1 [  ] Second task'
    assert_line -n 2 -p '2 [  ] First task'
}

@test "move - swaps item with item below" {
    # given
    __create_three_tasks
    # when
    run $YACT move 2 down
    #then
    assert_line -n 2 -p '2 [  ] Third task'
    assert_line -n 3 -p '3 [  ] Second task'
}

@test "move - doesn't change list if up first item" {
    # given
    __create_three_tasks
    # when
    run $YACT move 1 up
    #then
    assert_line -n 1 -p '1 [  ] First task'
}

@test "move - doesn't change list if top first item" {
    # given
    __create_three_tasks
    # when
    run $YACT move 1 top
    #then
    assert_line -n 1 -p '1 [  ] First task'
}

@test "move - doesn't change list if down last item" {
    # given
    __create_three_tasks
    # when
    run $YACT move 3 down
    #then
    assert_line -n 3 -p '3 [  ] Third task'
}

@test "move - doesn't change list if bottom last item" {
    # given
    __create_three_tasks
    # when
    run $YACT move 3 bottom
    #then
    assert_line -n 3 -p '3 [  ] Third task'
}

@test "Use editor if no description if provided for the new task" {
    # given
    export EDITOR=nano
    _spy_tool nano 'echo "The new description" > $1'
    # when
    run $YACT add 
    #then
    assert_output -p '1 [  ] The new description'
}

