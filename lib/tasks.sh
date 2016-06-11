
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
  printf '\n %s\n\n' $(color "${header}" $underline $bold)

  local doneText=''
  IFS=';'
  while read -r id task is_done; do
    if [ -z "$id" ]; then
      printf ' %s\n' "There are now tasks defined yet."
      break
    fi
    doneText=''
    if [ "$is_done" = '1' ]; then
      is_true $HIDE_DONE && continue 
      doneText=$(color ok $green)
    fi
    printf " %3d [%-2s] %s %s\n" $id "$doneText" $(wrap_text $task)
  done <<< "$(sed '1,2d'  $file | sort -t';' -n -k1)"
  printf '\n'

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
