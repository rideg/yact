#!/bin/bash
# YACT - Yet Another Command line TODO
# Copyright(c) 2016 Sandor Rideg
# MIT Licensed

set_done() {
  if [[ -z "$1" ]]; then
    fatal "Missing task id. Please provide it in order to set it to done."
  fi
  sed -ie "s/^\($1;.*\)[01]$/\1$2/w $RUN/.changed" "$FILE"
  if [[ ! -s "$RUN/.changed" ]]; then
   fatal "Cannot find task with id $1"
  fi
  show_tasks
}

add_task() {
  test -z "$*" && fatal "Please provide task description."
  maxId=$(sed '1,2d' "$FILE" | sort -t';' -rn -k1 | head -n1 | cut -d';' -f 1)
  ((maxId++))
  printf '%d;%s;0\n' $maxId "$*" >> "$FILE"
  show_tasks
}

delete_task() {
  test -z "$1" && fatal "Please provide a task id."
  grep -v "^$1;.*$" "$FILE" |  \
  awk 'BEGIN{id=1; FS=";"; OFS=";"}; {if (NR > 2) {$1=id++;}; print}' > "$RUN/.tmp"
  local ch_lines
  ch_lines=$(comm -2 -3 "$FILE" "$RUN/.tmp" 2>/dev/null | wc -l | sed 's/ *//')
  if [[ "$ch_lines" = '0' ]]; then
   fatal "Cannot find line with id: $1"
  fi
  mv "$RUN/.tmp" "$FILE"
  show_tasks
}

modify_task() {
  local description
  local id
  test -z "$1" && fatal "Please provide a task id."
  id=$1
  shift
  if [[ ! -z "$*" ]]; then
    description="$*"
  else
    local tmp_file
    tmp_file=$(create_tmp_file "$(grep "^$id;" "$FILE" | cut -d';' -f2)")
    launch_editor "$tmp_file"
    description=$(get_tmp_file_content "$tmp_file")
  fi
  test -z "$description" && fatal "Please provide the new description."
  sed -ie "s/^\($id;\).*\(;.*\)$/\1$description\2/w $RUN/.changed" "$FILE"
  if [[ ! -s "$RUN/.changed" ]]; then
   fatal "Cannot find task with id $id"
  fi
  show_tasks
}

show_tasks() {
  local IFS=''
  local header
  header=$(head -n1 "$FILE")

  local done_text=''
  local list_text=''
  local nr_of_done=0
  local nr_of_tasks=0
  IFS=';'
  while read -r id task is_done; do
    if [[ -z "$id" ]]; then
      break
    fi
    ((nr_of_tasks++))
    done_text=''
    if [[ "$is_done" = '1' ]]; then
      is_true "$HIDE_DONE" && continue
      done_text=$(color ok "$GREEN")
      ((nr_of_done++))
    fi
    list_text=$list_text$(printf ' %3d [%-2s] %s\n' "$id" "$done_text" "$(_wrap_text "$task")")
    list_text="$list_text\n"
  done <<<"$(sed '1,2d'  "$FILE" | sort -t';' -n -k1)"
  
  printf '\n %s - (%d/%d)\n\n' "$(color "$header" "$UNDRLINE" "$BOLD")" $nr_of_done $nr_of_tasks
  if [[ $nr_of_tasks -eq 0 ]]; then
    echo -e " There are now tasks defined yet.\n"
  else
    echo -e "$list_text"
  fi
}

_wrap_text() {
  local text=$*
  local length=${#text}
  if [[ "$length" -gt "$LINE_LENGTH" ]]; then
    local IFS=' '
    local line=''
    local wrapped=''
    for word in $text; do
      local t="$line $word"
      if [[ ${#t} -gt "$LINE_LENGTH" ]]; then
        wrapped="$wrapped$line\n          "
        line=''
      fi
      if [[ ${#line} -gt 0 ]]; then
       line=$t
      else
       line=$word
      fi
    done
  else
    line=$text
  fi
  wrapped="$wrapped$line"
  printf '%s' "$wrapped"
}