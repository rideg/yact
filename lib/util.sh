#!/usr/bin/env bash

################################################################################
# Checks if a value is true.
# -- Globals: None
# -- Input:
#  value - value to be checked.
# -- Output: true if the value is 1
################################################################################
is_true() {
  test "$1" -eq 1
}

################################################################################
# Prints the current timestamp.
# -- Globals: None
# -- Input: None
# -- Output: The current timestamp.
################################################################################
timestamp() {
  date +"%s"
}

################################################################################
# Cleans runtime tmp folder, restore working directory then exits.
# -- Globals:
#  YACT_DIR - Working directory for YACT.
# -- Input:
#  exit_code - Code to exit with.
# -- Output: None
################################################################################
exit_() {
  rm -f "$YACT_DIR"/.run/* &> /dev/null
  popd &> /dev/null
  exit "$1"
}

################################################################################
# Prints an error message to the stderr and then quits.
# -- Globals: None
# -- Input:
#  message - The error message.
# -- Output: The error message.
################################################################################
fatal() {
 printf '%s\n' "$1" >&2
 exit_ 1
}

################################################################################
# Creates a YACT template file for providing more complext descriptions.
# -- Globals: None
# -- Input:
#  file_name - The name of the file.
# -- Output: The path of the file.
################################################################################
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

################################################################################
# Launches the system editor to edit a given file.
# -- Globals:
#  EDITOR - System text editor.
# -- Input:
#  file - The file to be read.
# -- Output: None
################################################################################
launch_editor() {
  local cmd
  local file="$1"
  cmd="$EDITOR"
  test -z "$cmd" && cmd=vi
  which $cmd &> /dev/null
  test $? -eq 1 && fatal "Cannot find a suitable editor: $cmd"
  test ! -f "$file" && fatal "Non existing file: $file"
  $cmd "$file"
}

################################################################################
# Reads the content from a YACT template file.
# -- Globals: None
# -- Input:
#  file - The file to be read.
# -- Output: The content of the file.
################################################################################
get_tmp_file_content() {
  local file="$1"
  local description
  while read -r line || [[ -n $line ]]; do
    if [[ ! $line =~ ^#.* ]]; then #if it does not start with a #
      description="${description}${line} "
    fi
  done < "$file"
  trim "$description"
}

################################################################################
# Wraps a text into multiple lines if it is too long.
# -- Globals:
#  LINE_LENGTH - Line length to be taken into consideration when wrapping text.
# -- Input:
#  Text - the text to be wrapped.
# -- Output: Wrapped text.
################################################################################
wrap_text() {
  local text=$*
  local length=${#text}
  if [[ "$length" -gt "$LINE_LENGTH" ]]; then
    local IFS=' '
    local line=''
    local wrapped=''
    for word in $text; do
      local t="$line $word"
      if [[ ${#t} -gt "$LINE_LENGTH" ]]; then
        wrapped="$wrapped$line\n          "
        line=''
      fi
      if [[ ${#line} -gt 0 ]]; then
       line=$t
      else
       line=$word
      fi
    done
  else
    line=$text
  fi
  wrapped="$wrapped$line"
  printf '%s' "$wrapped"
}

################################################################################
# Trims a string
# -- Globals: None
# -- Input:
#  string - the string to be trimmed.
# -- Output: trimmed string.
################################################################################
trim() {
  local string="$1"
  string=${string#"${string%%[![:space:]]*}"}
  string=${string%"${string##*[![:space:]]}"}
  echo -n "$string"
}