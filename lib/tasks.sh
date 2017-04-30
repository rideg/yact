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
  local position
  local max_id
  if [[ "$1" == '-p' ]]; then
    position="$2"
    shift 2
  fi

  get_description "$*" " "
  max_id=$(sed '1,2d' "$FILE" | sort -t';' -rn -k1 | head -n1 | cut -d';' -f 1)
  ((max_id++))
  printf '%d;%s;0\n' $max_id "$__" >> "$FILE"

  if [[ -n "$position" ]]; then
    move_task "$max_id" "$position"
  fi
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
  local force=0
  if [[ "$1" == "-f" ]]; then
    force=1
    shift
  fi
  [[ $# -eq 0 ]] && fatal "Please provide a task id."
  if [[ $force -eq 0 ]]; then
    echo "Are you sure you want to delete? y/[n]"
    read -r -s -n 1 consent
  fi
  if [[ $force -eq 1 || "$consent" == "y" ]]; then
    while IFS=$'\n' read -r task_id; do
      local tmp_file="$RUN/.tmp"
      local task_to_delete
      test -z "$task_id"
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
      mv "$RUN/.tmp" "$FILE"
      unset task_to_delete
    done <<<"$(printf '%s\n' "$@" | sort -gr)"
  fi
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
  get_description "$*" "$(grep "^$id;" "$FILE" | cut -d';' -f2)"
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
  read_file
  local id=$1
  local position=$2
  is_number "$id" || fatal "The provided id is not numeric [${id}]"
  _get_position "$id" "$position"
  position=$__  
  is_number "$position" || fatal "The provided position is not numeric [${2}]"
  [[ $id -gt ${#TASKS[@]} ]] || [[ $id -lt 0 ]] \
    && fatal "There is no task with the provided id [$id]"
  [[ $position -gt ${#TASKS[@]} ]] || [[ $position -lt 0 ]] \
    && fatal "Non existing position [$position]"
  ((id--))
  ((position--))
  if [[ $id -ne $position ]]; then
    local tmp="${TASKS[$id]}"
    unset "TASKS[$id]"
    # some sort of bug in Bash
    TASKS=("${TASKS[@]}")
    TASKS=(
      "${TASKS[@]:0:$position}"
      "$tmp"
      "${TASKS[@]:$position}"
    )
    flush_file
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
    case "$position" in
      up)
        position=$id
        [[ "$position" -gt 1 ]] && ((position--))
        ;;
      top)
        position=1
        ;;
      down)
        position=$id
        [[ "$position" -lt ${#TASKS[@]} ]] && ((position++))
        ;;
      bottom)
        position=${#TASKS[@]}
        ;;
    esac
  fi
  __="$position"
}

################################################################################
# Parses a given todo item into an array
# -- Globals: None
# -- Input: Task line
# -- Output: Array of task line elements (id, description, status)
################################################################################
parse_item() {
  IFS=';' read -r -a __ <<< "$1"
}

################################################################################
# Shows a summary of the current list, which includes the list's' name and
# and a list of tasks.
# -- Globals:
#  HEADER - Current todo's header.
#  TASKS - Current todo's tasks.
#  HIDE_DONE - Global indicating whether the done task should be shown or not.
#  GREEN - Green color.
#  UNDRLINE - Underline formatting.
#  BOLD - Bold formatting.
# -- Input: None
# -- Output: The summary of the current list.
################################################################################
show_tasks() {
  read_file
  local list_text=''
  local nr_of_done=0
  local line_text
  local i=0
  
  while [[ $i -lt ${#TASKS[@]} ]]; do
    parse_item "${TASKS[$i]}"
    ((i++))
    local task="${__[1]}"
    local is_done="${__[2]}"
    local done_text=''
    if [[ "$is_done" == '1' ]]; then
      ((nr_of_done++))
      is_true "$HIDE_DONE" && continue
      done_text=$(format ok "$GREEN")
    fi
    line_text=$(printf ' %3d [%-2s] %s\n' \
      "$i" "$done_text" "$(wrap_text "$task")")
    list_text="${list_text}${line_text}\n"
  done

  printf '\n %s - (%d/%d)\n\n' \
    "$(format "$HEADER" \
    "$UNDRLINE" "$BOLD")" \
    $nr_of_done ${#TASKS[@]} 
  if [[ ${#TASKS[@]} -eq 0 ]]; then
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
  local task_id=$1
  local text
  local status
  local is_changed=0

  [[ -z $task_id ]] && fatal 'Missing task id.'
  [[ $2 != "" ]] && text=$2
  [[ -n $3 && $3 != "" ]] && status=$3

  local tmp_file="$RUN/tmp_task.txt"

  head -n2 "$FILE" > "$tmp_file"
  while IFS=';' read -r id task is_done; do
    if [[ "$id" -ne $task_id ]]; then
      printf '%d;%s;%d\n' "$id" "$task" "$is_done" >> "$tmp_file"
    else
      is_changed=1
      echo -n "$id;" >> "$tmp_file"
      if [[ -z "$text" ]]; then
        echo -n "$task;" >> "$tmp_file"
      else
        echo -n "$text;" >> "$tmp_file"
      fi
      if [[ -z "$status" ]]; then
        printf '%d\n' "$is_done" >> "$tmp_file"
      else
        printf '%d\n' "$status" >> "$tmp_file"
      fi
    fi
  done <<<"$(sed '1,2d'  "$FILE")"
  if [[ "$is_changed" -eq 0 ]]; then
    fatal "Cannot find task with id $id"
  fi
  mv "$RUN/tmp_task.txt" "$FILE"
}

