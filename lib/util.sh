#!/usr/bin/env bash

################################################################################
# Tests if a given variable is numeric
# -- Globals: None
# -- Input:
#  value - value to be checked.
# -- Output: true if the value is number
################################################################################
yact::util::is_number() {
  [[ "$1" =~ ^-?[0-9]+$ ]]
}

################################################################################
# Checks if a value is true.
# -- Globals: None
# -- Input:
#  value - value to be checked.
# -- Output: true if the value is 1
################################################################################
yact::util::is_true() {
  test "$1" -eq 1
}

################################################################################
# Prints the current date time.
# -- Globals: None
# -- Input:
# -- Output: The current date time.
################################################################################
yact::util::date_time() {
  date +"%Y-%m-%d_%H%M%S"
}

################################################################################
# Prints the current timestamp.
# -- Globals: None
# -- Input: None
# -- Output: The current timestamp.
################################################################################
yact::util::timestamp() {
  date +"%s"
}

################################################################################
# Cleans runtime tmp folder, restore working directory then exits.
# -- Globals: None
# -- Input:
#  exit_code - Status code to exit with.
# -- Output: None
################################################################################
yact::util::exit_() {
  # shellcheck disable=SC2164
  popd &> /dev/null
  #set +x
  #exec 2>&3 3>&-
  exit "$1"
}

################################################################################
# Prints an error message to the stderr and then quits.
# -- Globals: None
# -- Input:
#  message - The error message.
# -- Output: The error message.
################################################################################
yact::util::fatal() {
  printf '%s\n' "$1" >&2
  yact::util::exit_ 1
}

################################################################################
# Creates a YACT template file for providing more complex descriptions.
# -- Globals:
#  RUN - Directory for runtime temporary files.
# -- Input:
#  file_name - The name of the file.
# -- Output: None
# -- Return: The path to the file.
################################################################################
yact::util::create_tmp_file() {
  local file_name
  file_name="$RUN/_tmp.file.txt"
  cat > "$file_name" <<- EOF
	# This is a YACT description template file.
	# Empty, and all lines starting with # will be ignored.
	
EOF
  test $? -eq 1 && yact::util::fatal "Cannot create tmp file: $file_name"
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
yact::util::launch_editor() {
  local cmd
  local file="$1"
  cmd="$EDITOR"
  test -z "$cmd" && cmd='vi'
  command -v "$cmd" &> /dev/null
  test $? -eq 1 && yact::util::fatal "Cannot find a suitable editor: $cmd"
  test ! -f "$file" && yact::util::fatal "Non existing file: $file"
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
yact::util::get_tmp_file_content() {
  local file="$1"
  local description
  while read -r line || [[ -n $line ]]; do
    if [[ ! $line =~ ^#.* ]]; then #if it does not start with a #
      description="${description}${line} "
    fi
  done < "$file"
  yact::util::trim "$description"
  rm -f "$file"
}

################################################################################
# Wraps a text into multiple lines if it is too long.
# -- Globals: None
# -- Input:
#  Text - the text to be wrapped.
#  Max Id - the greatest id used in the task array.
#  Max length - the maximal line length
# -- Output: Wrapped text.
################################################################################
yact::util::wrap_text() {
  local text=$1
  local max_length=$3
  local IFS=' '
  local line=''
  local wrapped=''
  ((s_padding = ${#2} + 7))
  # shellcheck disable=SC2183
  printf -v padding '%*s' "$s_padding"
  for word in $text; do
    local t="$line $word"
    if [[ ${#t} -gt "$max_length" ]]; then
      wrapped=$wrapped$line$'\n'$padding
      line=''
    fi
    if [[ ${#line} -gt 0 ]]; then
      line=$t
    else
      line=$word
    fi
  done
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
yact::util::trim() {
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
yact::util::get_description() {
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
    yact::util::create_tmp_file "$old"
    yact::util::launch_editor "$__"
    yact::util::get_tmp_file_content "$__"
  fi
  [[ -z "$__" ]] && yact::util::fatal "Please provide description."
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
yact::util::check_task_id() {
  yact::util::check_range "$1" "${#TASKS[@]}"
}

################################################################################
# Checks if a given value is a valid list id.
# -- Globals:
#  LISTS - List of list files.
# -- Input:
#  id - The given id to be checked.
# -- Output: none
################################################################################
yact::util::check_list_id() {
  yact::util::check_range "$1" "${#LISTS[@]}"
}

################################################################################
# Checks if a given value is a valid index within a range.
# -- Globals: None
# -- Input:
#  id - The given id to be checked.
#  max - Upper limit.
# -- Output: none
################################################################################
yact::util::check_range() {
  [[ -z "$1" ]] && yact::util::fatal "Please provide a position"
  yact::util::is_number "$1" || yact::util::fatal \
    "The given position is not numeric [$1]"
  [[ $1 -lt 1 || $1 -gt "$2" ]] &&
    yact::util::fatal "Out of range position [$1]"
}

################################################################################
# Reads a given or the current todo file from the disk.
# -- Globals:
#  HEADER - Current todo's header.
#  TASKS - Current todo's tasks array.
# -- Inputs:
#  file_name? - a file name to be read.
# -- Output: none
################################################################################
yact::util::read_task_file() {
  readarray -t __ < "${1-$FILE}"
  TASKS=("${__[@]:2}")
  HEADER="${__[0]}"
  export TASKS HEADER
}

################################################################################
# Reads list file names into an array.
# -- Globals:
#  LISTS - List of list files.
# -- Inputs: none
# -- Output: none
################################################################################
yact::util::read_lists() {
  LISTS=("$STORAGE_DIR"/*.txt)
  export LISTS
}

################################################################################
# Stores tasks and headers.
# -- Globals:
#  HEADER - Current todo's header.
#  TASKS - Current todo's tasks array.
#  __STORED_HEADER - Stored header.
#  __STORED_TASKS - Stored tasks.
# -- Inputs: none
# -- Output: none
################################################################################
yact::util::store_current() {
  __STORED_TASKS=("${TASKS[@]}")
  __STORED_HEADER="$HEADER"
}

################################################################################
# Restores tasks and headers.
# -- Globals:
#  HEADER - Current todo's header.
#  TASKS - Current todo's tasks array.
#  __STORED_HEADER - Stored header.
#  __STORED_TASKS - Stored tasks.
# -- Inputs: none
# -- Output: none
################################################################################
yact::util::restore_current() {
  TASKS=("${__STORED_TASKS[@]}")
  HEADER="$__STORED_HEADER"
}

################################################################################
# Flushes the current todo file to the disk if changed.
# -- Globals:
#  FILE - Current todo list's file.
#  HEADER - Current todo's header.
#  TASKS - Current todo's tasks array.
#  __ORIGINAL_TASKS - Current todo's tasks array (original).
#  __ORIGINAL_HEADER - Current todo's header (original).
# -- Inputs:
#  file - File to flush tasks. Defaults to FILE.
# -- Output: none
################################################################################
yact::util::flush_task_file() {
  local file=${1-$FILE}
  if [[ "${TASKS[*]}" != "${__STORED_TASKS[*]}" || "$HEADER" != "$__STORED_HEADER" ]]; then
    printf '%s\n\n' "$HEADER" > "$file"
    if [[ ${#TASKS[@]} -gt 0 ]]; then
      printf '%s\n' "${TASKS[@]}" >> "$file"
    fi
  fi
}

################################################################################
# Syntactic sugar to simplify return value assignment. Usage:
#    let: my_var = command "$arg1" "$arg2"
# -- Globals: none
# -- Input:
#  variable - The name of the variable into which the result should be saved.
#  =        - Equal sign to support sugar.
#  command  - The command to be executed.
#  args...? - Command arguments.
# -- Output: none
################################################################################
let:() {
  local ret
  if [[ "$1" == '-a' ]]; then
    ret=$'("${__[@]}")'
    shift
  else
    ret=$'"$__"'
  fi
  [[ $# -lt 3 ]] && yact::util::fatal "Not enough arguments."
  [[ "$2" != '=' ]] && yact::util::fatal "Usage: let: <variable name> = command [args...]"
  local variable=$1
  local command=$3
  shift 3
  local args=("$@")
  for elem in "${args[@]}"; do
    args[${#args[@]}]="\"$elem\""
  done
  eval "$command ${args[*]:$#} ;$variable=$ret"
}

################################################################################
# Calculates the Levenshtein distance between two strings.
# -- Globals: none
# -- Input:
#   str1: first string
#   str2: second string
# -- Output:
#   __: the Levenshtein distance
################################################################################
yact::util::lev_dist() {
  [[ $# -ne 2 ]] && yact::util::fatal "Two arguments are required."
  local str1=$1
  local str2=$2
  declare -a v1
  declare -a v2
  declare -a tmp
  for ((i = 0; i <= ${#str2}; i++)); do
    v1[i]=$i
  done
  for ((i = 0; i < ${#str1}; i++)); do
    ((v2[0] = i + 1))
    for ((j = 0; j < ${#str2}; j++)); do
      local cost=0
      if [[ "${str1:$j:1}" != "${str2:$i:1}" ]]; then
        cost=1
      fi
      ((a = v2[j] + 1))
      ((b = v1[j + 1] + 1))
      ((c = v1[j] + cost))
      ((v2[j + 1] = a < b ? (a < c ? a : (b < c ? b : c)) : (b < c ? b : (c < a ? c : a))))
    done
    tmp=("${v1[@]}")
    v1=("${v2[@]}")
    v2=("${tmp[@]}")
  done
  __=("${v1[${#str2}]}")
}

################################################################################
# Executes the given command and reads the output into a variable
# -- Globals: none
# -- Input:
#   variable_name: The name of the variable to save the output.
#   args...: The command to be executed.
# -- Output: none
################################################################################
yact::util::read_to() {
  [[ "$1" == '-v' ]] || yact::util::fatal "Variable name is mandatory."
  local var="$2"
  shift 2
  eval "$* 1>&9"
  printf '\1' 1>&9
  read -r -u 9 -s -d $'\1' "$var"
}

################################################################################
# Checks if the actual list exists and if so then reads it to a global
# array.
# -- Globals:
#  FILE - Current todo list's file.
#  FILE_CONTENT - lines of the file as an array.
# -- Input: Arguments for list operations.
# -- Output: None.
################################################################################
yact::util::require_actual() {
  [[ -f "$FILE" ]] ||
    yact::util::fatal 'No todo list has been selected, please select/create one.'
  yact::util::read_task_file "$FILE"
  yact::util::store_current
}
