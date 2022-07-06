#!/usr/bin/env bash

# Creates a new list with the given description and marks it as current.
# -- Globals:
#  STORAGE_DIR - storage
#  RUN - Directory for runtime temporary files.
# -- Input:
#  Description - The description of the new list.
# -- Output: The list status after adding the new list
################################################################################
yact::list::new() {
  yact::util::get_description "$*" " "
  local description=$__
  yact::util::read_to -v id yact::util::timestamp
  while [[ -e "$STORAGE_DIR/_${id}.txt" ]]; do
    ((id++))
  done
  file_name="$STORAGE_DIR/_$id.txt"
  printf "%s\\n\\n" "$description" > "$file_name"
  printf 'TODO_FILE=%s\n' "$file_name" > "$RUN/.last"
  yact::list::_update_actual
}

################################################################################
# Marks the given list as current.
# -- Globals:
#  LISTS - list of list files.
#  RUN - Directory for runtime temporary files.
# -- Input:
#  id - The id of the list to be marked.
# -- Output: The list status after changing the current.
################################################################################
yact::list::switch() {
  yact::util::check_list_id "$1"
  file_name="${LISTS[$1 - 1]}"
  printf 'TODO_FILE=%s\n' "$file_name" > "$RUN/.last"
  yact::list::_update_actual
}

################################################################################
# Deletes the given list and marks the last recently used as current. Or if no
# id is provided it deletes the current list.
# -- Globals:
#  RUN - Directory for runtime temporary files.
#  FILE - current todo list
# -- Input:
#  id? -  Id of the list to be deleted.
# -- Output: The list status after deleting the list.
################################################################################
yact::list::delete() {
  local to_delete="$FILE"
  local consent

  if [[ -n "$1" ]]; then
    yact::util::check_list_id "$1"
    to_delete="${LISTS[$1 - 1]}"
  fi
  yact::util::read_to -v header head -n 1 "$to_delete"
  # shellcheck disable=SC2154
  echo "List name: $header"
  echo "Are you sure to delete? y/[n]"
  read -r -s -n 1 consent

  if [[ $consent == 'y' ]]; then
    rm -f "$to_delete" &> /dev/null
    if [[ "$to_delete" == "$FILE" ]]; then
      local next_file
      # shellcheck disable=SC2012
      next_file="$(ls -ur "$STORAGE_DIR"/_*.txt 2> /dev/null | head -n1)"
      if [[ -z "$next_file" ]]; then
        rm "$RUN"/.last
      else
        printf 'TODO_FILE=%s\n' "$next_file" > "$RUN"/.last
        yact::list::_update_actual
      fi
    fi
  fi
}

################################################################################
# Updates the description of a given list.
# -- Globals:
#  RUN - Directory for runtime temporary files.
# -- Input:
#  id -  Id of the list to be changed.
#  description - The new description.
# -- Output: The list status after changing the description.
################################################################################
yact::list::modify() {
  local description
  local id=$1
  yact::util::check_list_id "$id"
  local file="${LISTS[$id - 1]}"
  shift
  yact::util::store_current
  yact::util::read_task_file "$file"
  let: HEADER = yact::util::get_description "$@" "$HEADER"
  yact::util::flush_task_file "$file"
  yact::list::restore_current
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
yact::list::show() {
  local -i done_tasks
  local -i index
  local l=${#LISTS[@]}
  local indicator
  yact::format::format 'You have the following lists' "$BOLD" "$UNDERLINE"
  printf \ "\\n%s:\\n\\n" "$__"
  for actual_file in "${LISTS[@]}"; do
    indicator=''
    ((index++))
    if [[ "$actual_file" == "$FILE" ]]; then
      indicator=' *'
    fi
    done_tasks=0
    readarray -t __ < "$actual_file"
    for item in "${__[@]:2}"; do
      [[ ${item: -1} -eq 1 ]] && ((done_tasks++))
    done
    printf " %${#l}d %s (%d/%d)%s\\n" "$index" "${__[0]}" "$done_tasks" \
      "$((${#__[@]} - 2))" "$indicator"
  done
  printf '\n'
}

################################################################################
# Updates FILE global.
# -- Globals:
#  RUN - Directory for runtime temporary files.
#  TODO_FILE - The file name of the current list.
#  FILE - current todo list
# -- Input: None
# -- Output: The list status.
################################################################################
yact::list::_update_actual() {
  # shellcheck source=/dev/null
  . "$RUN/.last"
  FILE="$TODO_FILE"
  _require_actual
}
