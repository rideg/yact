#!/usr/bin/env bash

################################################################################
# Marks a given task as done or not done.
# -- Globals:
#  RUN - Directory for runtime temproray files.
#  FILE - Current todo list's file.
# -- Input:
#  id - Id of task to be changed.
# -- Output: The item status after the change.
################################################################################
set_done() {
  if [[ -z $1 ]]; then
    fatal "Missing task id. Please provide it in order to set it to done."
  fi
  sed -i '' "s/^\($1;.*\)[01]$/\1$2/w $RUN/.changed" "$FILE"
  if [[ ! -s "$RUN/.changed" ]]; then
   fatal "Cannot find task with id $1"
  fi
  show_tasks
}

################################################################################
# Adds a new task to the current list.
# -- Globals:
#  FILE - Current todo list's file.
# -- Input:
#  description -  Description of the new task.
# -- Output: The item status after the change.
################################################################################
new_task() {
  test -z "$*" && fatal "Please provide task description."
  maxId=$(sed '1,2d' "$FILE" | sort -t';' -rn -k1 | head -n1 | cut -d';' -f 1)
  ((maxId++))
  printf '%d;%s;0\n' $maxId "$*" >> "$FILE"
  show_tasks
}

################################################################################
# Removes task from the current list.
# -- Globals:
#  FILE - Current todo list's file.
#  RUN - Directory for runtime temproray files.
# -- Input:
#  id -  Task id to be deleted.
# -- Output: The item status after the deletion.
################################################################################
delete_task() {
  local task_id=$1
  test -z "${task_id}" && fatal "Please provide a task id."
  grep -v "^$1;.*$" "$FILE" |  \
  awk 'BEGIN{id=1; FS=";"; OFS=";"}; {if (NR > 2) {$1=id++;}; print}' \
    > "$RUN/.tmp"
  local ch_lines
  ch_lines=$(comm -2 -3 "$FILE" "$RUN/.tmp" 2>/dev/null | wc -l | sed 's/ *//')
  if [[ "$ch_lines" = '0' ]]; then
   fatal "Cannot find line with id: ${task_id}"
  fi
  mv "$RUN/.tmp" "$FILE"
  show_tasks
}

################################################################################
# Updates the given task's description.
# -- Globals:
#  FILE - Current todo list's file.
#  RUN - Directory for runtime temproray files.
# -- Input:
#  id -  Task id to be deleted.
# -- Output: The item status after the change.
################################################################################
modify_task() {
  local description
  local id=$1
  test -z "$id" && fatal "Please provide a task id."
  shift
  if [[ -n "$*" ]]; then
    description="$*"
  else
    local tmp_file
    tmp_file=$(create_tmp_file "$(grep "^$id;" "$FILE" | cut -d';' -f2)")
    launch_editor "$tmp_file"
    description=$(get_tmp_file_content "$tmp_file")
  fi
  test -z "$description" && fatal "Please provide the new description."
  sed -i '' "s/^\($id;\).*\(;.*\)$/\1$description\2/w $RUN/.changed" "$FILE"
  if [[ ! -s "$RUN/.changed" ]]; then
   fatal "Cannot find task with id $id"
  fi
  show_tasks
}

################################################################################
# Moves a given task to a given position within the current list.
# -- Globals:
#  FILE - Current todo list's file.
#  RUN - Directory for runtime temproray files.
# -- Input:
#  id -  Task id to be moved.
#  position - Target position.
# -- Output: The item status after the move.
################################################################################
move_task() {
  local id=$1
  local position=$2
  is_number "$id" || fatal "The provided id is not numeric [${id}]"
  position=$(_get_position "$id" "$position")
  is_number "$position" \
    || fatal "The provided position is not numeric [${2}]"

  if [[ $id -ne $position ]]; then
    local tmp_file
    local task_line

    tmp_file="${RUN}/tmp_$(timestamp).txt"
    head -n2 "$FILE" > "$tmp_file"
    task_line=$(sed '1,2d' "$FILE" | grep -e "^${id};")
    test -n "$task_line" \
            || fatal "There is no task with the provided id [${id}]"

    local start=$id
    local end=$position
    local shift_value=-1
    local verify_position=0
    if [[ $end -lt $start ]]; then
      local tmp=$end
      end=$start
      start=$tmp
      shift_value=1
    fi
    while IFS=';' read -r current_id rest; do
      if [[ "$current_id" -ge $start && "$current_id" -le $end ]]; then
        if [[ "$current_id" -eq "$position" ]]; then 
           printf '%s;%s\n' "$current_id" "${task_line/${id};/}" >> "$tmp_file"
           printf '%d;%s\n' $((current_id + shift_value)) "$rest" >> "$tmp_file"
           verify_position=1
        elif [[ "$current_id" -eq "$id" ]]; then
            :
        else
          printf '%d;%s\n' $((current_id + shift_value)) "$rest" >> "$tmp_file"
        fi
      else
        printf '%s;%s\n' "$current_id" "$rest" >> "$tmp_file"
      fi
    done <<<"$(sed '1,2d'  "$FILE" | sort -t';' -n -k1)"
    test $verify_position -eq 1 || fatal "Non existing position [${position}]"
    mv "$tmp_file" "$FILE"
  fi
  show_tasks
}

################################################################################
# Provides numeric position for textual position.
# -- Globals:
#  FILE - Current todo list's file.
# -- Input:
#  id -  Task id to be moved.
#  position - Target position (numeric or "up"/"down"/"bottom"/"top")
# -- Output: The numeric position.
################################################################################
_get_position() {
  local id=$1
  local position=$2
  if ! is_number "$position"; then
    number_of_items=$(($(sed '1,2d'  "$FILE" | wc -l)))
    case "$position" in
          up)
            position=$id
            test "$position" -gt 1 && ((position--))
          ;;
          top)
            position=1
          ;;
          down)
            position=$id
            test "$position" -lt "$number_of_items" && ((position++))
          ;;
          bottom)
            position="$number_of_items"
          ;;
      esac
  fi
  echo -n "$position"
}

################################################################################
# Shows a summary of the current list, which includes the list's' name and
# and a list of tasks.
# -- Globals:
#  FILE - Current todo list's file.
#  HIDE_DONE - Global indicating whether the done task should be shown or not.
#  GREEN - Green color.
#  UNDRLINE - Underline formatting.
#  BOLD - Bold formatting.
# -- Input: None
# -- Output: The summary of the current list.
################################################################################
show_tasks() {
  local line_text
  local done_text=''
  local list_text=''
  local nr_of_done=0
  local nr_of_tasks=0

  while IFS=';' read -r id task is_done; do
    if [[ -z "$id" ]]; then
      break
    fi
    ((nr_of_tasks++))
    done_text=''
    if [[ "$is_done" = '1' ]]; then
      is_true "$HIDE_DONE" && continue
      done_text=$(format ok "$GREEN")
      ((nr_of_done++))
    fi
    line_text=$(printf ' %3d [%-2s] %s\n' \
              "$id" "$done_text" "$(wrap_text "$task")")
    list_text="${list_text}${line_text}\n"
  done <<<"$(sed '1,2d'  "$FILE" | sort -t';' -n -k1)"
  
  printf '\n %s - (%d/%d)\n\n' \
         "$(format "$(head -n1 "$FILE")" \
         "$UNDRLINE" "$BOLD")" \
         $nr_of_done $nr_of_tasks

  if [[ $nr_of_tasks -eq 0 ]]; then
    echo -e " There are now tasks defined yet.\n"
  else
    echo -e "$list_text"
  fi
}
