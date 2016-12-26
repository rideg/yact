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
  if [[ "$#" -eq 0 ]]; then
    fatal "Please provide description for the new list." 
  fi
  id=$(timestamp)
  while [[ -e "$YACT_DIR/_${id}.txt" ]]; do
    ((id++))
  done
  file_name="_$id.txt"
  printf "%s\n\n" "$*" > "$YACT_DIR/$file_name"
  printf 'TODO_FILE=%s\n' "$file_name" > "$YACT_DIR/.last"
  _update_file_and_show
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
  _update_file_and_show
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
  test -n "$1" && to_delete="$YACT_DIR/_${1}.txt"
  rm -f "$to_delete" &> /dev/null
  if [[ "$to_delete" = "$FILE" ]]; then
    local next_file
    next_file="$(ls -ur "$YACT_DIR"/_*.txt 2> /dev/null | head -n1)"
    if [[ -z "$next_file" ]]; then
      rm "$YACT_DIR"/.last
    else
      printf 'TODO_FILE=%s\n' "$(basename "$next_file")" > "$YACT_DIR"/.last
      _update_file_and_show
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
  test -n "$id" || fatal 'Please provide an id.'
  local file="${YACT_DIR}/_${id}.txt"
  test -f "$file" || fatal "Non existing file. ${file}"
  shift
  description="$*"
  if [[ -z "$description" ]]; then
    local tmp_file
    tmp_file="$(create_tmp_file "$(head -n1 "$file")")"
    launch_editor "$tmp_file"
    description=$(get_tmp_file_content "$tmp_file")
  fi
  sed -i'' -e "1s/.*/$description/" "$file" \
      || fatal "Could not update file: $file"
  _update_file_and_show
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
show_list() {
  local indicator
  printf \
    "\n %s:\n\n" "$(format 'You have the following lists' "$BOLD" "$UNDERLINE")"
  for actual_file in $(ls -ur "$YACT_DIR"/_*.txt); do
    if [[ "$actual_file" = "$FILE" ]]; then
     indicator='*'
    fi
    printf ' %-1s %s\t%s\n' "$indicator" \
            "$(_TMP=${actual_file/*_/}; printf '%s' "${_TMP/\.txt/}")" \
            "$(_file_header_with_info "$actual_file")"
    indicator=''
  done
  printf '\n'
}

################################################################################
# Prints the current list status to the stdout.
# -- Globals: None
# -- Input: None
# -- Output: The list status.
################################################################################
_file_header_with_info() {
  local file="$1"
  local number_of_done=0
  local number_of_tasks=0
  while IFS=';' read -r -s id description status; do
    if [[ -n $description ]]; then
      ((number_of_tasks++))
      if [[ $status -eq 1 ]]; then
        ((number_of_done++))
      fi
    fi
  done <<<"$(sed '1,2d'  "$file" | sort -t';' -n -k1)"
  printf '%s (%d/%d)' "$(head -n1 "$file")" $number_of_done $number_of_tasks
}

################################################################################
# Updates FILE global.
# -- Globals:
#  YACT_DIR - Working directory for YACT.
#  TODO_FILE - The file name of the current list.
# -- Input: None
# -- Output: The list status.
################################################################################
_update_file_and_show() {
  # shellcheck source=/dev/null
  . "$YACT_DIR/.last"
  FILE="$YACT_DIR/$TODO_FILE"
  show_list
}
