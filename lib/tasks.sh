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
  local position=$2
  is_number "$id" || fatal "The provided id is not numeric [${id}]"
  _get_position "$id" "$position"
  position=$__  
  check_task_id "$id"
  check_task_id "$position"
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
  local nr_of_done=0
  local buffer=()
  local i=0
  for item in "${TASKS[@]}"; do
    local is_done="${item: -1}"
    local done_text='  '
    ((i++))
    if [[ $is_done -eq 1 ]]; then
      ((nr_of_done++))
      is_true "$HIDE_DONE" && continue
      format ok "$GREEN"
      done_text="$__"
    fi
    wrap_text "${item:0:$((${#item}-2))}"
    buffer[${#buffer[@]}]=$i
    buffer[${#buffer[@]}]="$done_text"
    buffer[${#buffer[@]}]="$__"
  done
  format "$HEADER" "$UNDRLINE" "$BOLD"
  printf '\n %s - (%d/%d)\n\n' "$__" $nr_of_done ${#TASKS[@]} 
  if [[ ${#TASKS[@]} -eq 0 ]]; then
    echo " There are now tasks defined yet."
  else
    printf ' %3d [%s] %s\n' "${buffer[@]}"
  fi
  echo ""
}

