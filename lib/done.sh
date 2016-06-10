#!/bin/sh


set_done() {
 if [ -z $1 ]; then
   fatal "Missing task id. Please provide it in order to set it to done."  
 fi
 sed -ie "s/^\($1;.*\)[01]$/\1$2/w .changed"  $TODO_FILE 
 if [ ! -s .changed ]; then
  fatal "Cannot find task with id $1"
 fi
 show_tasks
}
