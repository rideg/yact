#!/bin/bash

pushd $(dirname $0) &> /dev/null
cd ..

test -z ${YACT_DIR} && YACT_DIR=~/.yact
RUN=$YACT_DIR/.run

test ! -e $RUN && mkdir -p $RUN
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

FILE=$YACT_DIR/$TODO_FILE

test $# -eq 0 && show_tasks
test "$1" = '--done' -o "$1" = '-d' && set_done "$2" 1
test "$1" = '--undone' -o "$1" = '-u' && set_done "$2" 0
test "$1" = '--add' -o "$1" = '-a' && shift && add_task "$*"
test "$1" = "--delete" && delete_task $2
exit_ 0
