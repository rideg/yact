
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
  local IFS=''
  local header=$(head -n1 $TODO_FILE)
  printf '\n %s\n\n' $(color "${header}" $underline $bold)

  local doneText=''
  IFS=';'
  local addSeparator=0
  while read -r id task is_done; do
    if [ -z "$id" ]; then
      printf ' %s\n' "There are now tasks defined yet." 
      break
    fi
    doneText=''
    if [ "$is_done" = '1' ]; then
      doneText=$(color ok $green)
      if [ $SEPARATE_DONE -eq 1 -a $addSeparator -eq 0 ]; then
        printf "\n"
        addSeparator=1
      fi
    fi
    printf " %3d [%-2s] %s %s\n" $id "$doneText" $(wrap_text $task)
  done <<< "$(sed '1,2d'  $TODO_FILE | sort -t';' -n -k3.1)"
  printf '\n'

}
