#!/usr/bin/env bash

################################################################################
# Marks a given task as done or not done.
# -- Globals:
#  TASKS - Current todo list's tasks array.
# -- Input:
#  id -  Task id to be deleted.
# -- Output: None 
################################################################################
set_done() {
  local id=$1
  check_task_id "$id"
  shift
  ((id--))
  parse_item "${TASKS[$id]}" 
  TASKS[$id]="${__[0]};$1"
}

################################################################################
# Adds a new task to the current list.
# -- Globals:
#  TASKS - Current todo list's tasks array.
# -- Input:
#  description -  Description of the new task.
# -- Output: The item status after the change.
################################################################################
add_task() {
  local position
  if [[ "$1" == '-p' ]]; then
    position="$2"
    shift 2
  fi
  get_description "$*" " "
  TASKS=("${TASKS[@]}" "$__;0")
  if [[ -n "$position" ]]; then
    move_task "${#TASKS[@]}" "$position"
  fi
}

################################################################################
# Removes task from the current list.
# -- Globals:
#  TASKS - Current todo list's tasks array.
# -- Input:
#  id -  Task ids to be deleted.
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
    [[ "$consent" != "y" ]] && return
  fi
  declare -a tasks=("${TASKS[@]}")
  for id in "$@"; do
    check_task_id "$id"
    local task_id=$((id - 1))
    unset "tasks[$task_id]"
  done
  TASKS=("${tasks[@]}")
}

################################################################################
# Updates the given task's description.
# -- Globals:
#  TASKS - Current todo list's tasks array.
# -- Input:
#  id -  Task id to be deleted.
# -- Output: The item status after the change.
################################################################################
modify_task() {
  local id=$1
  declare -a task_array
  local description
  check_task_id "$id"
  shift
  ((id--))
  let: -a task_array = parse_item "${TASKS[$id]}" 
  let: description = get_description "$*" "${task_array[0]}"
  TASKS[$id]="$description;${task_array[1]}"
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
  local position
  is_number "$id" || fatal "The provided id is not numeric [${id}]"
  let: position = _get_position "$id" "$2"
  check_task_id "$id"
  check_task_id "$position"
  ((id--))
  ((position--))
  if [[ $id -ne $position ]]; then
    local tmp="${TASKS[$id]}"
    unset "TASKS[$id]"
    # some sort of bug in Bash
    TASKS=("${TASKS[@]}")
    TASKS=("${TASKS[@]:0:$position}" "$tmp" "${TASKS[@]:$position}")
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
  local -i d
  local -a buffer
  local -i i
  for item in "${TASKS[@]}"; do
    ((i++))
    if [[ ${item: -1} -eq 1 ]]; then
      ((d=d+1))
      if [[ $HIDE_DONE -eq 1 ]]; then
        continue
      fi
      buffer[${#buffer[@]}]=$i
      buffer[${#buffer[@]}]=${GREEN}ok${NORMAL}
    else
      buffer[${#buffer[@]}]=$i
      buffer[${#buffer[@]}]='  '
    fi
    if [[ ${#item} -ge $LINE_LENGTH ]]; then
      wrap_text ${item::-2}
      buffer[${#buffer[@]}]=$__
    else
      buffer[${#buffer[@]}]=${item::-2}
    fi
  done
  printf '\n %s - (%d/%d)\n\n' \
    "$BOLD$UNDERLINE$HEADER$NORMAL" "$d" "${#TASKS[@]}"
  if [[ ${#TASKS[@]} -eq 0 ]]; then
    echo ' There are now tasks defined yet.'
  else
    printf " %${#i}d [%s] %s\n" "${buffer[@]}"
  fi
  echo
}

################################################################################
# Swaps two tasks in the tasklist
# -- Globals:
#   TASKS - Currenct todos's tasks.
# -- Input:
#   id1 -- First task id
#   id2 -- Second task id
# -- Output: none
################################################################################
swap_tasks() {
  check_task_id "$1"
  check_task_id "$2"
  local -i id1=$(($1 - 1))
  local -i id2=$(($2 - 1))
  local tmp="${TASKS[$id1]}"
  TASKS[$id1]="${TASKS[$id2]}"
  TASKS[$id2]="$tmp"
}

