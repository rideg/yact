#!/usr/bin/env bash

# Creates a new list with the given description and marks it as current.
# -- Globals:
#  STORAGE_DIR - storage
#  RUN - Directory for runtime temproray files.
# -- Input:
#  Description - The description of the new list.
# -- Output: The list status after adding the new list
################################################################################
new_list() {
  get_description "$*" " "
  local description=$__
  read_to -v id timestamp
  while [[ -e "$STORAGE_DIR/_${id}.txt" ]]; do
    ((id++))
  done
  file_name="_$id.txt"
  printf "%s\n\n" "$description" > "$STORAGE_DIR/$file_name"
  printf 'TODO_FILE=%s\n' "$file_name" > "$RUN/.last"
  _update_actual
}

################################################################################
# Marks the given list as current.
# -- Globals:
#  STORAGE_DIR - storage
#  RUN - Directory for runtime temproray files.
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
  if [[ ! -f "$STORAGE_DIR/$file_name" ]]; then
    fatal "Non-existing list id $list_id"
  fi
  printf 'TODO_FILE=%s\n' "$file_name" > "$RUN/.last"
  _update_actual
}

################################################################################
# Deletes the given list and marks the last recently used as current. Or if no
# id is provided it deletes the current list.
# -- Globals:
#  STORAGE_DIR - storage
#  RUN - Directory for runtime temproray files.
#  FILE - current todo list
# -- Input:
#  id? -  Id of the list to be deleted.
# -- Output: The list status after deleting the list.
################################################################################
delete_list() {
  local to_delete="$FILE"
  local consent

  [[ -n "$1" ]] && to_delete="$STORAGE_DIR/_${1}.txt"
  [[ -f "$to_delete" ]] || fatal "Non-existing list id: $1"
  
  read_to -v header head -n 1 "$to_delete"
  # shellcheck disable=SC2154
  echo "List name: $header"
  echo "Are you sure to delete? y/[n]"
  read -r -s -n 1 consent

  if [[ $consent == 'y' ]]; then
    rm -f "$to_delete" &> /dev/null
    if [[ "$to_delete" = "$FILE" ]]; then
      local next_file
      # shellcheck disable=SC2012
      next_file="$(ls -ur "$STORAGE_DIR"/_*.txt 2> /dev/null | head -n1)"
      if [[ -z "$next_file" ]]; then
        rm "$RUN"/.last
      else
        printf 'TODO_FILE=%s\n' "$(basename "$next_file")" > "$RUN"/.last
        _update_actual
      fi
    fi
  fi
}

################################################################################
# Updates the description of a given list.
# -- Globals:
#  STORAGE_DIR - storage
#  RUN - Directory for runtime temproray files.
# -- Input:
#  id -  Id of the list to be changed.
#  description - The new description.
# -- Output: The list status after changing the description.
################################################################################
modify_list() {
  local description
  local id=$1
  [[ -n "$id" ]] || fatal 'Please provide an id.'
  local file="${STORAGE_DIR}/_${id}.txt"
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
#  STORAGE_DIR - storage
#  BOLD - bold formatting
#  FILE - current todo list
#  UNDERLINE - underline formatting
# -- Input: None
# -- Output: The list status.
################################################################################
show_lists() {
  local -i d
  local indicator
  format 'You have the following lists' "$BOLD" "$UNDERLINE"
  printf \ "\n %s:\n\n" "$__"
  for actual_file in "$STORAGE_DIR"/_*.txt; do
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
#  STORAGE_DIR - storage
#  RUN - Directory for runtime temproray files.
#  TODO_FILE - The file name of the current list.
#  FILE - current todo list
# -- Input: None
# -- Output: The list status.
################################################################################
_update_actual() {
  # shellcheck source=/dev/null
  . "$RUN/.last"
  FILE="$STORAGE_DIR/$TODO_FILE"
  _require_actual
}

