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
#  Max Id - the greatest id used in the task array.
#  Max length - the maximal line length
# -- Output: Wrapped text.
################################################################################
wrap_text() {
  local text=$1
  local max_length=$3
  let s_padding=${#2}+7
  local IFS=' '
  local line=''
  local wrapped=''
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

################################################################################
# Reads a given or the current todo file from the disk.
# -- Globals:
#  HEADER - Current todo's header.
#  TASKS - Current todo's tasks array.
# -- Inputs:
#  file_name? - a file name to be read.
# -- Output: none
################################################################################
read_task_file() {
  readarray -t __ < "${1-$FILE}"
  TASKS=("${__[@]:2}")
  HEADER="${__[0]}"
  export TASKS HEADER
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
store_current() {
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
restore_current() {
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
flush_task_file() {
  local file=${1-$FILE}
  if [[ "${TASKS[*]}" != "${__STORED_TASKS[*]}" || \
        "$HEADER" != "$__STORED_HEADER" ]]; then
    printf '%s\n\n' "$HEADER" > "$file"
    if [[ ${#TASKS[@]} -gt 0 ]]; then
      printf '%s\n' "${TASKS[@]}" >> "$file"
    fi
  fi
}

################################################################################
# Syntactic sugar to simplifie return value assignment. Usage:
#    let: my_var = command "$arg1" "$arg2"
# -- Globals: none
# -- Input:
#  variable - The name of the variable into which the result sould be saved.
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
  [[ $# -lt 3 ]] && fatal "Not enought arguments."
  [[ "$2" != '=' ]] && fatal "Usage: let: <variable name> = command [args...]"
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
lev_dist() {
 [[ $# -ne 2 ]] && fatal "Two arguments are required." 
 local str1=$1
 local str2=$2
 declare -a v1
 declare -a v2 
 declare -a tmp
 for (( i=0; i<=${#str2}; i++ )); do
   v1[$i]=$i
 done
 for (( i=0; i<${#str1}; i++ )); do
   let v2[0]=i+1
   for (( j=0; j<${#str2}; j++ )); do
     local cost=0
     if [[ "${str1:$j:1}" != "${str2:$i:1}" ]]; then
       cost=1
     fi 
     let a=v2[j]+1
     let b=v1[j+1]+1 
     let c=v1[j]+cost
     let "v2[j+1]=a<b?(a<c?a:(b<c?b:c)):(b<c?b:(c<a?c:a))"
   done 
   tmp=(${v1[@]})
   v1=(${v2[@]})
   v2=(${tmp[@]})
 done
 __=(${v1[${#str2}]})
}

################################################################################
# Executest the given command and read the output into a variable
# -- Globals: none
# -- Input:
#   variable_name: The name of the variable to save output.
#   args...: The command to be executed.
# -- Output: none 
################################################################################
read_to() {
  [[ "$1" = '-v' ]] || fatal "Variable name is mandatory."
  local var="$2"
  shift 2
  eval "$* 1>&9"
  printf '%s' $'\1' 1>&9
  read -r -u 9 -s -d $'\1' "$var"
}

