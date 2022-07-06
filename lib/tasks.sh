#!/usr/bin/env bash

################################################################################
# Marks a given task as done or not done.
# -- Globals:
#  TASKS - Current todo list's tasks array.
# -- Input:
#  id -  Task id.
# -- Output: None
################################################################################
yact::task::set() {
  local id=$1
  check_task_id "$id"
  shift
  ((id--))
  yact::task::_parse_item "${TASKS[$id]}"
  if [[ ${__[2]} -eq 2 ]]; then # separator
    fatal "Cannot mark seprator: '${__[1]}' as done"
  fi
  TASKS[$id]="0;${__[1]};$1"
}

################################################################################
# Adds a new task to the current list.
# -- Globals:
#  TASKS - Current todo list's tasks array.
#  CONFIG - Configuration.
# -- Input:
#  description -  Description of the new task.
# -- Output: The item status after the change.
################################################################################
yact::task::add() {
  local position
  local item_type=0
  if [[ "$1" == '-s' ]]; then
    item_type=2
    shift
  fi
  if [[ "$1" == '-p' ]]; then
    position="$2"
    shift 2
  fi
  if [[ "$1" == '-s' ]]; then
    item_type=2
    shift
  fi
  get_description "$*" " "
  local task_line="0;$__;$item_type"
  local init_pos
  if [[ ${CONFIG[insert_top]} -eq 1 ]]; then
    TASKS=("$task_line" "${TASKS[@]}")
    init_pos=1
  else
    TASKS=("${TASKS[@]}" "0;$__;$item_type")
    init_pos=${#TASKS[@]}
  fi
  if [[ -n "$position" ]]; then
    yact::task::move "$init_pos" "$position"
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
yact::task::delete() {
  local force=0
  if [[ "$1" == "-f" ]]; then
    force=1
    shift
  fi
  declare -a ids=("$@")
  [[ $# -eq 0 ]] && fatal "Please provide at least one task to delete"
  if [[ $# -eq 1 ]]; then
    if [[ "$1" =~ [0-9]+-[0-9]+ ]]; then
      declare -i a=${1%-*}
      declare -i b=${1#*-}
      ((lower = a > b ? b : a))
      ((upper = a > b ? a - 1 : b - 1))
      check_task_id "$lower"
      check_task_id "$upper"
      eval "ids=({$lower..$upper})"
    elif [[ "$1" =~ [0-9]+.. ]]; then
      declare -i lower=${1::-2}
      check_task_id "$lower"
      eval "ids=({$lower..${#TASKS[@]}})"
    elif [[ "$1" =~ ..[0-9]+ ]]; then
      declare -i a=${1:2}
      ((upper = a - 1))
      check_task_id "$upper"
      eval "ids=({1..$upper})"
    fi
  fi
  declare -a tasks=("${TASKS[@]}")
  for id in "${ids[@]}"; do
    check_task_id "$id"
    local task_id=$((id - 1))
    local should_delete=1
    if [[ $force -eq 0 ]]; then
      printf 'Task: "%s"\n' "${tasks[$task_id]:2:-2}"
      printf 'Are you sure you want to delete? y/[n]\n'
      read -r -s -n 1 consent
      [[ "$consent" != 'y' ]] && should_delete=0
    fi
    if [[ $should_delete -eq 1 ]]; then
      unset "tasks[$task_id]"
    fi
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
yact::task::modify() {
  local id=$1
  declare -a task_array
  local description
  check_task_id "$id"
  shift
  ((id--))
  let: -a task_array = yact::task::_parse_item "${TASKS[$id]}"
  let: description = get_description "$*" "${task_array[1]}"
  TASKS[$id]="0;$description;${task_array[2]}"
}

################################################################################
# Moves a given task to a given position within the current list.
# -- Globals:
#  TASKS - Current todo list's tasks array.
# -- Input:
#  id -  Task id to be moved.
#  position - Target position.
# -- Output: The item status after the move.
################################################################################
yact::task::move() {
  local id=$1
  local position
  is_number "$id" || fatal "The provided id is not numeric [${id}]"
  let: position = yact::task::_get_position "$id" "$2"
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
yact::task::_get_position() {
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
yact::task::_parse_item() {
  IFS=';' read -r -a __ <<< "$1"
}

################################################################################
# Shows a summary of the current list, which includes the list's' name and a
# list of tasks.
# -- Globals:
#  CONFIG - Configuration.
#  HEADER - Current todo's header.
#  TASKS - Current todo's tasks.
#  GREEN - Green color.
#  UNDERLINE - Underline formatting.
#  BOLD - Bold formatting.
# -- Input: None
# -- Output: The summary of the current list.
################################################################################
yact::task::show() {
  local -i d
  local -a buffer
  local -i i
  ll='line_length'
  ((length = ${#TASKS[@]}))
  ((max_available = COLUMNS - 9 - ${#length}))
  # shellcheck disable=SC2149
  ((max_length = CONFIG[$ll] < max_available || max_available < 0 ? CONFIG[$ll] : max_available))
  local tag_pattern=".*[^${YELLOW}](#[^[:space:]]+).*"
  for item in "${TASKS[@]}"; do
    ((i = i + 1))
    ((stat = ${item: -1}))
    if [[ $stat -eq 1 ]]; then
      ((d = d + 1))
      if [[ ${CONFIG[hide_done]} -eq 1 ]]; then
        continue
      fi
      buffer[${#buffer[@]}]=$i
      buffer[${#buffer[@]}]="${GREEN}ok${NORMAL}"
    elif [[ $stat -eq 0 ]]; then
      buffer[${#buffer[@]}]=$i
      buffer[${#buffer[@]}]='  '
    else # separator
      buffer[${#buffer[@]}]=$i
      buffer[${#buffer[@]}]='##'
    fi
    local item_text=${item:2:-2}
    if [[ $stat -eq 2 ]]; then
      item_text=${item_text^^}
      ((pad_size = (max_length - ${#item_text}) > 0 ? (max_length - ${#item_text}) / 2 - 1 : 0))
      local pad
      eval "printf -v pad '%0.1s' '-'{1..$pad_size}"
      item_text="${pad}${item_text}${pad}"
    elif [[ ${CONFIG[use_formatting]} -eq 1 ]]; then
      item_text=" ${item_text}"
      while [[ $item_text =~ $tag_pattern ]]; do
        item_text=${item_text/${BASH_REMATCH[1]/\#/\\\#}/${YELLOW}${BASH_REMATCH[1]}${NORMAL}}
      done
      item_text=${item_text:1}
    fi
    if [[ ${#item_text} -ge $max_length ]]; then
      wrap_text "$item_text" "$length" "$max_length"
      buffer[${#buffer[@]}]=$__
    else
      buffer[${#buffer[@]}]=$item_text
    fi
  done
  printf '\n %s - (%d/%d)\n\n' \
    "$BOLD$UNDERLINE$HEADER$NORMAL" "$d" "${#TASKS[@]}"
  if [[ ${#TASKS[@]} -eq 0 ]]; then
    echo ' There are now tasks defined yet.'
  else
    printf " %${#i}d [%s] %s\\n" "${buffer[@]}"
  fi
  echo
}

################################################################################
# Swaps two tasks in the task list
# -- Globals:
#   TASKS - Current todos's tasks.
# -- Input:
#   id1 -- First task id
#   id2 -- Second task id
# -- Output: none
################################################################################
yact::task::swap() {
  check_task_id "$1"
  check_task_id "$2"
  local -i id1=$(($1 - 1))
  local -i id2=$(($2 - 1))
  local tmp="${TASKS[$id1]}"
  TASKS[$id1]="${TASKS[$id2]}"
  TASKS[$id2]="$tmp"
}

################################################################################
# Reverses the order of the tasks on the current list.
# -- Globals:
#   TASKS - Current todos's tasks.
# -- Input: none
# -- Output: none
################################################################################
yact::task::reverse() {
  local -i endId=${#TASKS[@]}-1
  local -i startId=0
  while [[ endId -gt startId ]]; do
    local tmp="${TASKS[$startId]}"
    TASKS[$startId]="${TASKS[$endId]}"
    TASKS[$endId]="$tmp"
    ((endId--))
    ((startId++))
  done
}
