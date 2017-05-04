#!/usr/bin/env bash

################################################################################
# Creates a new list with the given description and marks it as current.
# -- Globals:
#  YACT_DIR - Working directory for YACT.
# -- Input:
#  Description - The description of the new list.
# -- Output: The list status after adding the new list
################################################################################
new_list() {
  get_description "$*" " "
  local description=$__
  id=$(timestamp)
  while [[ -e "$YACT_DIR/_${id}.txt" ]]; do
    ((id++))
  done
  file_name="_$id.txt"
  printf "%s\n\n" "$description" > "$YACT_DIR/$file_name"
  printf 'TODO_FILE=%s\n' "$file_name" > "$YACT_DIR/.last"
  _update_actual
}

################################################################################
# Marks the given list as current.
# -- Globals:
#  YACT_DIR - Working directory for YACT.
# -- Input:
#  id - The id of the list to be marked.
# -- Output: The list status after changing the current.
################################################################################
switch_list() {
  local list_id="$1"
  if [[ -z "$list_id" ]]; then
    fatal "Missing list id, please provide it."
  fi
  file_name="_${list_id}.txt"
  if [[ ! -f "$YACT_DIR/$file_name" ]]; then
    fatal "Non-existing list id $list_id"
  fi
  printf 'TODO_FILE=%s\n' "$file_name" > "$YACT_DIR/.last"
  _update_actual
}

################################################################################
# Deletes the given list and marks the last recently used as current. Or if no
# id is provided it deletes the current list.
# -- Globals:
#  YACT_DIR - Working directory for YACT.
#  FILE - current todo list
# -- Input:
#  id? -  Id of the list to be deleted.
# -- Output: The list status after deleting the list.
################################################################################
delete_list() {
  local to_delete="$FILE"
  local consent

  test -n "$1" && to_delete="$YACT_DIR/_${1}.txt"

  echo "Are you sure to delete? y/[n]"
  read -r -s -n 1 consent

  if [[ $consent == 'y' ]]; then
    rm -f "$to_delete" &> /dev/null
    if [[ "$to_delete" = "$FILE" ]]; then
      local next_file
      next_file="$(ls -ur "$YACT_DIR"/_*.txt 2> /dev/null | head -n1)"
      if [[ -z "$next_file" ]]; then
        rm "$YACT_DIR"/.last
      else
        printf 'TODO_FILE=%s\n' "$(basename "$next_file")" > "$YACT_DIR"/.last
        _update_actual
      fi
    fi
  fi
}

################################################################################
# Updates the description of a given list.
# -- Globals:
#  YACT_DIR - Working directory for YACT.
# -- Input:
#  id -  Id of the list to be changed.
#  description - The new description.
# -- Output: The list status after changing the description.
################################################################################
modify_list() {
  local description
  local id=$1
  [[ -n "$id" ]] || fatal 'Please provide an id.'
  local file="${YACT_DIR}/_${id}.txt"
  [[ -f "$file" ]] || fatal "Non-existing file. ${file}"
  shift
  store_current
  read_task_file "$file"  
  let: HEADER = get_description "$@" "$HEADER"
  flush_task_file "$file"
  restore_current
}

################################################################################
# List the currently available todo lists and indicates the current with a *
# mark.
# -- Globals:
#  YACT_DIR - Working directory for YACT.
#  FILE - current todo list
#  BOLD - bold formatting
#  UNDERLINE - underline formatting
# -- Input: None
# -- Output: The list status.
################################################################################
show_lists() {
  local -i d
  local indicator
  format 'You have the following lists' "$BOLD" "$UNDERLINE"
  printf \ "\n %s:\n\n" "$__"
  for actual_file in "$YACT_DIR"/_*.txt; do
    if [[ "$actual_file" = "$FILE" ]]; then
      indicator='*'
    fi
    d=0
    readarray -t __ < "$actual_file"
    for item in "${__[@]:2}"; do
      [[ ${item: -1} -eq 1 ]] && ((d++)) 
    done
    actual_file=${actual_file#*_}
    actual_file=${actual_file%.txt*}
    printf ' %-1s %s\t%s (%d/%d)\n' "$indicator" \
      "$actual_file" \
      "${__[0]}" "$d" "$((${#__[@]}-2))"
    indicator=''
  done
  printf '\n'
}

################################################################################
# Updates FILE global.
# -- Globals:
#  YACT_DIR - Working directory for YACT.
#  TODO_FILE - The file name of the current list.
# -- Input: None
# -- Output: The list status.
################################################################################
_update_actual() {
  # shellcheck source=/dev/null
  . "$YACT_DIR/.last"
  FILE="$YACT_DIR/$TODO_FILE"
  _require_actual
}

