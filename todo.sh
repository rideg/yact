#!/bin/sh

pushd $(dirname $0) &> /dev/null


test -z ${YACT_DIR} && YACT_DIR=~/.yact

test ! -e $YACT_DIR && mkdir -p $YACT_DIR

. ./config

test -e $YACT_DIR/config && . $YACT_DIR/config
. lib/util.sh
. lib/colors.sh
. lib/lists.sh
. lib/tasks.sh

if [ "$1" = '-l' ]; then
 if [ "$2" = "--new" -o "$2" = "-n" ]; then
  shift 2
  new_list $* 
 elif [ "$2" = "--switch" -o "$2" = "-s" ]; then
  switch_list $3
 fi
fi

test -e $YACT_DIR/.last && . $YACT_DIR/.last

if [ -z $TODO_FILE ]; then
  fatal "No todo list has been selected, please select/create one."
fi

test $# -eq 0 && show_tasks
test "$1" = '--done' -o "$1" = '-d' && set_done "$2" 1
test "$1" = '--undone' -o "$1" = '-u' && set_done "$2" 0
if [ "$1" = '--add' -o "$1" = '-a' ]; then
  shift
  test -z "$*" && fatal "Please provide task description"
  add_task "$*"
fi
exit_ 0
