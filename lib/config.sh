#!/usr/bin/env bash

# Available config names
declare -A CONFIG_OPTIONS=(
  [hide_done]="If set done tasks won't be shown;bool"
  [insert_top]="If set new tasks will be inserted to the top of the list;bool"
  [line_length]="Maximum line length before wrapping text;positive-number"
  [use_formatting]="Turns formatting on or off;bool"
)

################################################################################
# Updates a given configuration parameter with a given value.
# -- Globals:
#  CONFIG_OPTIONS - Available configurations.
# -- Input:
#  config_name - Option name.
#  value - The value to be set.
# -- Output: None
# -- Return: None
################################################################################
yact::config::set_config() {
  [[ ${CONFIG_OPTIONS[$1]+1} -eq 1 ]] ||
    yact::util::fatal "No option with name: $1"
  config_type=${CONFIG_OPTIONS[$1]##*;}
  yact::config::validate_type "$config_type" "$2"
  CONFIG[$1]="$2"
  yact::config::write_config
}

################################################################################
# Prints the value of the given configuration parameter.
# -- Globals:
#  CONFIG_OPTIONS - Available configurations.
# -- Input:
#  config_name - Option name.
# -- Output: None
# -- Return: None
################################################################################
yact::config::get_config() {
  [[ ${CONFIG_OPTIONS[$1]+1} -eq 1 ]] ||
    yact::util::fatal "No option with name: $1"
  printf 'name:         %s\n' "$1"
  printf 'description:  %s\n' "${CONFIG_OPTIONS[$1]%;*}"
  printf 'value:        %s\n' "${CONFIG[$1]}"
}

################################################################################
# Resets a given configuration parameter to its default.
# -- Globals:
#  CONFIG_OPTIONS - Available configurations.
# -- Input:
#  config_name - Option name.
# -- Output: None
# -- Return: None
################################################################################
yact::config::unset_config() {
  [[ ${CONFIG_OPTIONS[$1]+1} -eq 1 ]] ||
    yact::util::fatal "No option with name: $1"
  unset "CONFIG[$1]"
  yact::config::write_config
}

################################################################################
# Validates whether the given value satisfies the given type restrictions.
# -- Globals: None
# -- Input:
#  config_type: The type to be used.
#  value: The value to be tested against the given type.
# -- Output: None
# -- Return: None
################################################################################
yact::config::validate_type() {
  local config_type="$1"
  local value="$2"
  case $config_type in
    bool)
      [[ "$value" == '0' || "$value" == '1' ]] ||
        yact::util::fatal "The given value: '$value' is not a boolean."
      ;;
    number)
      yact::util::is_number "$value" ||
        yact::util::fatal "The given value: '$value' is not a number."
      ;;
    non-empty-text)
      [[ -n "$value" ]] ||
        yact::util::fatal "The given value is empty"
      ;;
    positive-number)
      # shellcheck disable=SC2015
      yact::util::is_number "$value" && [[ $value -ge 0 ]] ||
        yact::util::fatal "The given value: '$value' is not a positive number."
      ;;
    negative-number)
      # shellcheck disable=SC2015
      yact::util::is_number "$value" && [[ $value -lt 0 ]] ||
        yact::util::fatal "The given value: '$value' is not a negative number."
      ;;
  esac
}

################################################################################
# Shows the available configuration values.
# -- Globals:
#  CONFIG_OPTIONS - Available configurations.
# -- Input: None
# -- Output: None
# -- Return: None
################################################################################
yact::config::print_config() {
  declare -a output=()
  ((max_key = -1))
  for key in "${!CONFIG_OPTIONS[@]}"; do
    output[${#output[@]}]="$key"
    output[${#output[@]}]="${CONFIG_OPTIONS[$key]%;*}"
    ((max_key = "max_key < ${#key} ? ${#key} : max_key"))
  done
  ((max_key = max_key + 2))
  local format="%-${max_key}s--  %s\\n"
  [[ "$1" == '-c' ]] && format="%s:%s\\n"
  # shellcheck disable=SC2059
  printf "$format" "${output[@]}"
}

################################################################################
# Flushes configuration to file.
# -- Globals:
#  YACT_DIR - Working directory for YACT.
#  CONFIG - Configuration.
# -- Input: None
# -- Output: None
# -- Return: None
################################################################################
yact::config::write_config() {
  local cfg=$YACT_DIR/config
  printf '#!/usr/bin/env bash\n\n' > "$cfg"
  for entry in "${!CONFIG[@]}"; do
    printf 'CONFIG[%s]=%s\n' "$entry" "${CONFIG[$entry]}" >> "$cfg"
  done
}
