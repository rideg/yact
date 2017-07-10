#!/usr/bin/env bash

# Available config names
declare -A CONFIG_OPTIONS=(
  [hide_done]="If set done tasks won't be shown;bool"
  [insert_top]="If set new tasks will be inserted to the top of the list;bool"
  [line_length]="Maximum line lenght before wrapping text;positive-number"
  [use_formatting]="Turns formatting on or off;bool"
)

################################################################################
# Updates a given config param with a given value.
# -- Globals:
#  CONFIG_OPTIONS - Available configurations.
# -- Input:
#  config_name - Option name.
#  value - The value to be set.
# -- Output: None
# -- Return: None
################################################################################
set_config() {
  [[ ${CONFIG_OPTIONS[$1]+1} -eq 1 ]] || fatal "No option with name: $1"
  config_type=${CONFIG_OPTIONS[$1]##*;}
  validate_type "$config_type" "$2"
  CONFIG[$1]="$2"
  write_config
}

################################################################################
# Resets a given config param to its default.
# -- Globals:
#  CONFIG_OPTIONS - Available configurations.
# -- Input:
#  config_name - Option name.
# -- Output: None
# -- Return: None
################################################################################
unset_config() {
  [[ ${CONFIG_OPTIONS[$1]+1} -eq 1 ]] || fatal "No option with name: $1"
  unset "CONFIG[$1]"
  write_config
}

################################################################################
# Validates whether the given value satifies the given type restrictions.
# -- Globals: None
# -- Input:
#  config_type: The type to be used.
#  value: The value to be tested against the given type.
# -- Output: None
# -- Return: None
################################################################################
validate_type() {
  local config_type="$1"
  local value="$2"
  case $config_type in
    bool)
      [[ "$value" == '0' || "$value" == '1' ]] || \
        fatal "The given value: '$value' is not a boolean."
      ;;
    number)
      is_number "$value" || \
        fatal "The given value: '$value' is not a number."
      ;;
    non-empty-text)
      [[ -n "$value" ]] || \
        fatal "The given value is empty"
      ;;
    positive-number)
       # shellcheck disable=SC2015
       is_number "$value" && [[ $value -ge 0 ]] || \
         fatal "The given value: '$value' is not a positive number."
       ;;
    negative-number)
       # shellcheck disable=SC2015
       is_number "$value" && [[ $value -lt 0 ]] || \
         fatal "The given value: '$value' is not a negative number."
       ;;
  esac
}

################################################################################
# Shows the available config values.
# -- Globals: 
#  CONFIG_OPTIONS - Available configurations.
# -- Input: None
# -- Output: None
# -- Return: None
################################################################################
print_config() {
  declare -a output=()
  let max_key=-1
  for key in "${!CONFIG_OPTIONS[@]}"; do
    output[${#output[@]}]="$key"
    output[${#output[@]}]="${CONFIG_OPTIONS[$key]%;*}"
    let max_key="max_key < ${#key} ? ${#key} : max_key"
  done
  let max_key=max_key+2
  local format="%-${max_key}s--  %s\n" 
  [[ "$1" == '-c' ]] && format="%s=%s\n"
  # shellcheck disable=SC2059
  printf "$format" "${output[@]}" 
}

################################################################################
# Flushes config to the config file.
# -- Globals:
#  YACT_DIR - Working directory for YACT.
#  CONFIG - Configuration.
# -- Input: None
# -- Output: None
# -- Return: None
################################################################################
write_config() {
  local cfg=$YACT_DIR/config
  printf '#!/usr/bin/env bash\n\n' > "$cfg"
  for entry in "${!CONFIG[@]}"; do
    printf 'CONFIG[%s]=%s\n' "$entry" "${CONFIG[$entry]}" >> "$cfg"
  done
}

