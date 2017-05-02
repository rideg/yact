#!/usr/bin/env bash

################################################################################
# Tests if a given variable is numeric
# -- Globals: None
# -- Input:
#  value - value to be checked.
# -- Output: true if the value is number
################################################################################
is_number() {
  [[ "$1" =~ ^-?[0-9]+$ ]]
}

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
#  RUN - Directory for runtime temproray files.
# -- Input:
#  exit_code - Code to exit with.
# -- Output: None
################################################################################
exit_() {
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
# -- Globals:
#  RUN - Directory for runtime temproray files.
# -- Input:
#  file_name - The name of the file.
# -- Output: None
# -- Return: The path to the file.
################################################################################
create_tmp_file() {
  local file_name
  file_name="$RUN/_tmp.file.txt"
  cat > "$file_name" <<- EOF
	# This is a YACT description template file.
	# Empty, and all lines starting with # will be ignored.
	
EOF
  test $? -eq 1 && fatal "Cannot create tmp file: $file_name"
  # Appends the given line to the file.
  test -n "$*" && echo "$*" >> "$file_name"
  __=$file_name
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
  if [[ "$cmd" == 'vi' || "$cmd" == 'vim' ]]; then
    cmd="${cmd} +4"
  fi
  $cmd "$file"
}

################################################################################
# Reads the content from a YACT template file.
# -- Globals: None
# -- Input:
#  file - The file to be read.
# -- Output: None
# -- Return: The content of the file.
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
  rm -f "$file"
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
  __="$wrapped$line"
}

################################################################################
# Trims a string
# -- Globals: None
# -- Input:
#  string - the string to be trimmed.
# -- Output: None
# -- Return: Trimmed string
################################################################################
trim() {
  local string="$1"
  string=${string#"${string%%[![:space:]]*}"}
  string=${string%"${string##*[![:space:]]}"}
  __="$string"
}

################################################################################
# Gets a description either from the arguments or from a tmp file.
# -- Globals: None
# -- Input:
#  description? - Description.
#  original - Original description.
# -- Output: None
# -- Return: Description.
################################################################################
get_description() {
  local new
  local old
  if [[ $# -eq 2 ]]; then
    new=$1
    old=$2
  else
    old=$1
  fi
  if [[ -n "$new" ]]; then
    __="$new"
  else
    create_tmp_file "$old"
    launch_editor "$__"
    get_tmp_file_content "$__"
  fi
  [[ -z "$__" ]] && fatal "Please provide description."
  # replace any new line character with spaces
  __=${__//$'\n'/ }
}

################################################################################
# Checks if a given value is a valid task id.
# -- Globals:
#  TASKS - Current todo's tasks array.
# -- Input:
#  id - The given id to be checked.
# -- Output: none
################################################################################
check_task_id() {
  [[ -z "$1" ]] && fatal "Please provide a position"
  is_number "$1" || fatal "The given position is not numeric [$1]"
  [[ $1 -lt 1 || $1 -gt ${#TASKS[@]} ]] && \
    fatal "Out of range task position [$1]"
}

