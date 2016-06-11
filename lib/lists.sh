#!/bin/bash

update_file_and_show() {
  . $YACT_DIR/.last
  FILE="$YACT_DIR/$TODO_FILE"
  show_list
}

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
  update_file_and_show 
}

switch_list() {
   if [ -z $1 ]; then
     fatal "Missing list id, please provide it."
   fi
   file_name=_${1}.txt
   if [ ! -f $YACT_DIR/$file_name ]; then
    fatal "Non-existing list id $1"
   fi
   printf 'TODO_FILE=%s\n' $file_name > $YACT_DIR/.last
   update_file_and_show 
}

delete_list() {
  local to_delete=$FILE 
  if [ ! -z $1 ]; then
    to_delete="$YACT_DIR/_${1}.txt"
  fi
  rm -f $to_delete & > /dev/null
  if [ "$to_delete" = "$FILE" ]; then
    local next_file=$(ls -ur $YACT_DIR/_*.txt 2> /dev/null | head -n1)
    if [ -z $next_file ]; then
      rm $YACT_DIR/.last
    else
      printf 'TODO_FILE=%s\n' $(basename $next_file) > $YACT_DIR/.last
      update_file_and_show
    fi
  fi
}

file_header_with_info() {
  awk '\
     BEGIN {\
       done=0; 
       count=0;
       FS=";";
     }\
     {\
        if (NR == 1) { \
         printf $0\
        };\
        if(NR > 2) {\
         count++; \
         if ($3 == "1") {\
           done++;\
          }\
        }\
     }; END {printf " (%d/%d)", count, done; }' $1
}

show_list() {
  printf "\n $(color 'You have the following lists' $bold $underline):\n\n"
  for actual_file in $(ls -ur $YACT_DIR/_*.txt); do
    if [ "$actual_file" = "$FILE" ]; then
     indicator='*'
    else
     indicator=''
    fi
    printf ' %-1s %s\t%s\n' "$indicator" $(echo $actual_file | sed -e 's:^.*/_\(.*\)\.txt$:\1:') "$(file_header_with_info $actual_file)"
  done
  printf '\n'
}
