#!/bin/bash
# YACT - Yet Another Command line TODO
# Copyright(c) 2016 Sandor Rideg
# MIT Licensed

is_true() {
  test "$1" -eq 1
}

timestamp() {
  date +"%s"
}

exit_() {
  rm -f "$YACT_DIR"/.run/* &> /dev/null
  popd &> /dev/null
  exit "$1"
}

fatal() {
 printf '%s\n' "$1"
 exit_ 1
}

create_tmp_file() {
  local file_name
  file_name="/tmp/yact_tmp$(timestamp).txt"
  cat > "$file_name" <<- EOF
	# This is a YACT description template file.
	# Empty, and all lines starting with # will be ignored.
	
	EOF
  test $? -eq 1 && fatal "Cannot create tmp file: $file_name"
  # Appends the given line to the file.
  test -n "$*" && echo "$*" >> "$file_name"
  printf '%s' "$file_name"
}

launch_editor() {
  local cmd
  cmd="$EDITOR"
  test -z "$cmd" && cmd=vi
  which $cmd &> /dev/null
  test $? -eq 1 && fatal "Cannot find a suitable editor: $cmd"
  $cmd "$1"
}

get_tmp_file_content() {
  local description
  while read -r line || [[ -n $line ]]; do
    if [[ ! $line =~ ^#.* ]]; then #if it does not start with a #
      description="$description$line "
    fi
  done < "$1"
  printf '%s' "$description"
}
