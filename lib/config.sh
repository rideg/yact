#!/usr/bin/env bash

# Available config names
declare -A CONFIG_OPTIONS=(
  [hide_done]="If set done tasks won't be shown;bool"
  [line_length]="Maximum line lenght before wrapping text;number"
  [use_formatting]="If false then no formatting used when printing text;bool"
)

################################################################################
# Updates a given config param with a given value.
# -- Globals:
#  YACT_DIR - Working directory for YACT.
# -- Input:
#  config - Configuration description (must be a in a format of name=value)
# -- Output: None
# -- Return: None
################################################################################
set_config() {
  IFS='=' read -ra split <<< "$1"
  [[ ${#split[@]} -ne 2 ]] && fatal "Invalid config. $1"
  [[ ${CONFIG_OPTIONS[${split[0]}]+1} -eq 1 ]] || \
    fatal "No option with name: ${split[0]}"
  config_type=${CONFIG_OPTIONS[${split[0]}]##*;}
  validate_type "$config_type" "${split[1]}"
  CONFIG[${split[0]}]="${split[1]}"
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
      [[ $value -eq 0 || $value -eq 1 ]] || \
        fatal "The given value: '$value' is not a boolean."
      ;;
    number)
      is_number "$value" || \
        fatal "The given value '$value' is not a number."
      ;;
    non-empty-text)
      [[ -n "$value" ]] \
        fatal "The given value is empty"
      ;;
    positive-number)
       # shellcheck disable=SC2015
       is_number "$value" && [[ $value -ge 0 ]] || \
         fatal "The given value '$value' is not a positive number"
       ;;
    negative-number)
       # shellcheck disable=SC2015
       is_number "$value" && [[ $value -lt 0 ]] || \
         eatal "The given value '$value' is not a negative number"
       ;;
  esac
}

################################################################################
# Flushes config to the config file.
# -- Globals:
#  YACT_DIR - Working directory for YACT.
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
  printf ')\n' >> "$cfg"
}

