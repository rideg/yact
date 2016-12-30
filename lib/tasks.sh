#!/usr/bin/env bash

################################################################################
# Marks a given task as done or not done.
# -- Globals:
#  RUN - Directory for runtime temproray files.
#  FILE - Current todo list's file.
# -- Input:
#  id - Id of task to be changedj
# -- Output: The item status after the change.
################################################################################
set_done() {
  _change_task "$1" "" "$2"
}

################################################################################
# Adds a new task to the current list.
# -- Globals:
#  FILE - Current todo list's file.
# -- Input:
#  description -  Description of the new task.
# -- Output: The item status after the change.
################################################################################
add_task() {
  get_description "$@"
  maxId=$(sed '1,2d' "$FILE" | sort -t';' -rn -k1 | head -n1 | cut -d';' -f 1)
  ((maxId++))
  printf '%d;%s;0\n' $maxId "$__" >> "$FILE"
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
  local tmp_file="$RUN/.tmp"
  local task_to_delete
  test -z "$task_id" && fatal "Please provide a task id."

  head -n2 "$FILE" > "$tmp_file"
  while IFS=';' read -r id task is_done; do
    if [[ "$id" -lt $task_id ]]; then
		printf '%d;%s;%d\n' "$id" "$task" "$is_done" >> "$tmp_file"
	elif [[ "$id" -gt $task_id ]]; then
		printf '%d;%s;%d\n' $((id - 1)) "$task" "$is_done" >> "$tmp_file"
	else
		task_to_delete="$task"
	fi
  done <<<"$(sed '1,2d'  "$FILE" | sort -t';' -n -k1)"

  [[ -z "$task_to_delete" ]] && fatal "Cannot find line with id: $task_id"

  echo "Are you sure you want to delete? y/[n]"
  read -r -s -n 1 consent 
  [[ "$consent" == "y" ]] && mv "$RUN/.tmp" "$FILE"
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
  local id=$1
  test -z "$id" && fatal "Please provide a task id."
  shift
  get_description "$@"
  _change_task "$id" "$__"
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

################################################################################
# Changes a given task.
# -- Globals:
#  RUN - Directory for runtime temproray files.
#  FILE - Current todo list's file.
# -- Input:
#  id - Id of task to be changed
#  text? - The new text for the task - ignored if empty.
#  status? - The new status for the task - ignored if empty.
# -- Output: None.
################################################################################
_change_task() {
  test $# -lt 2 &&  fatal 'Not enough number of arguments for _change_task'
  local id=$1
  local text='\1'
  local status='\2'

  [[ -z $1 ]] && fatal 'Missing task id.'
  [[ $2 != "" ]] && text=$2
  [[ -n $3 && $3 != "" ]] && status=$3

  head -n2 "$FILE" >  "$RUN/tmp_task.txt"
  sed '1,2d' "$FILE" | \
    sed "s/^$1;\(.*\);\([01]\)/${id};${text};${status}/w $RUN/.changed" >> \
    "$RUN/tmp_task.txt"

  if [[ ! -s "$RUN/.changed" ]]; then
   fatal "Cannot find task with id $id"
  fi
  mv "$RUN/tmp_task.txt" "$FILE"
}

