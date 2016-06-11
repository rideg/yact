#!/bin/bash

new_list() {
  if [ -z "$*" ]; then
    fatal "Please provide description for the new list." 
  fi
  id=$(timestamp)
  while [ -e $YACT_DIR/"_${id}.txt" ]; do
    ((id++))
  done
  file_name="_$(timestamp).txt"
  printf "$*\n\n" > $YACT_DIR/$file_name
  printf 'TODO_FILE=%s\n' $file_name > $YACT_DIR/.last
}

switch_list() {
   if [ -z $1 ]; then
     fatal "Missing list id, please provide it."
   fi
   file_name=_${1}.txt
   if [ ! -f $YACT_DIR/$file_name ]; then
    fatal "Nonexisting list id $1"
   fi
   printf 'TODO_FILE=%s\n' $file_name > $YACT_DIR/.last
}

