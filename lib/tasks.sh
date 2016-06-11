
wrap_text() {
  local text=$*
  local length=${#text}
  if [ $length -gt $LINE_LENGTH ]; then
    local IFS=' '
    local line=''
    local wrapped=''
    for word in $text; do
      local t="$line $word"
      if [ ${#t} -gt $LINE_LENGTH ]; then
        wrapped="$wrapped$line\n          "
        line=''
      fi
      if [ ${#line} -gt 0 ]; then
       line=$t
      else
       line=$word
      fi
    done
  else
    line=$text
  fi
  wrapped="$wrapped$line"
  printf "$wrapped"
}

show_tasks() {
  local file=$YACT_DIR/$TODO_FILE
  local IFS=''
  local header=$(head -n1 $file)

  local done_text=''
  local list_text=''
  local nr_of_done=0
  local nr_of_tasks=0
  IFS=';'
  while read -r id task is_done; do
    if [ -z "$id" ]; then
      break 
    fi
    ((nr_of_tasks++))
    done_text=''
    if [ "$is_done" = '1' ]; then
      is_true $HIDE_DONE && continue 
      done_text=$(color ok $green)
      ((nr_of_done++))
    fi
    list_text=$list_text$(printf " %3d [%-2s] %s %s\n" $id "$done_text" $(wrap_text $task))
    list_text="$list_text\n"
  done <<< "$(sed '1,2d'  $file | sort -t';' -n -k1)"

  printf '\n %s - (%d/%d)\n\n' $(color "${header}" $underline $bold) $nr_of_done $nr_of_tasks
  if [ $nr_of_tasks -eq 0 ]; then
    printf " There are now tasks defined yet.\n\n"
  else 
    printf "$list_text\n"
  fi

}


set_done() {
 if [ -z $1 ]; then
   fatal "Missing task id. Please provide it in order to set it to done."
 fi
 sed -ie "s/^\($1;.*\)[01]$/\1$2/w .changed"  $YACT_DIR/$TODO_FILE
 if [ ! -s .changed ]; then
  fatal "Cannot find task with id $1"
 fi
 show_tasks
}

add_task() {
 maxId=$(sed '1,2d' $YACT_DIR/$TODO_FILE | sort -t';' -rn -k1 | head -n1 | cut -d';' -f 1)

 ((maxId++))

 printf '%d;%s;0\n' $maxId "$*" >> $YACT_DIR/$TODO_FILE
 show_tasks
}
