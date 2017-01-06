#!/usr/bin/env bash

# Mapping between human-readable and internal config
# variable naming.
declare -A __YACT_CONFIG=(\
  [hide_done]=HIDE_DONE \
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
  local config_file="$YACT_DIR/config"
  [[ ! -f "$config_file" ]] && touch "$config_file"
  declare -a split
  IFS='=' read -ra split <<< "$1"
  [[ ${#split[@]} -ne 2 ]] && fatal "Invalid config. $1"
  local variable=${__YACT_CONFIG["${split[0]}"]}
  [[ -n "$variable" ]] || fatal "Unknown config parameter: ${split[0]}"
  if grep -Fxq "export $variable=.*" "$config_file"; then
    sed -i '' "s/export $variable=.*/export $variable=${split[1]}/" \
    "$config_file" 2> /dev/null
  else
    echo "export $variable=${split[1]}" >> "$config_file"
  fi
  eval "$variable=${split[1]}"
}

