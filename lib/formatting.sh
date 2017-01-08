#!/usr/bin/env bash

################################################################################
# Initialize fromatting globals for colorized input if colors are enabled.
# -- Globals:
#  USE_FORMATTING - Configuration variable to enable/disable formatting.
# -- Input: None
# -- Output: None
################################################################################
_init_formatting() {
  if [[ "$(tput colors)" -gt 2 && $USE_FORMATTING -eq 1 ]] 2> /dev/null; then
    export BLACK RED GREEN YELLOW BLUE MAGENTA CYAN WHITE BOLD REVERSE \
      UNDERLINE BG_BLACK BG_RED BG_GREEN BG_YELLOW BG_BLUE BG_MAGENTA BG_CYAN \
      BG_WHITE NORMAL
    BLACK=$(tput setaf 0)
    RED=$(tput setaf 1)
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    BLUE=$(tput setaf 4)
    MAGENTA=$(tput setaf 5)
    CYAN=$(tput setaf 6)
    WHITE=$(tput setaf 7)
    BOLD=$(tput bold)
    REVERSE=$(tput smso)
    UNDERLINE=$(tput smul)

    BG_BLACK=$(tput setab 0)
    BG_RED=$(tput setab 1)
    BG_GREEN=$(tput setab 2)
    BG_YELLOW=$(tput setab 3)
    BG_BLUE=$(tput setab 4)
    BG_MAGENTA=$(tput setab 5)
    BG_CYAN=$(tput setab 6)
    BG_WHITE=$(tput setab 7)
    NORMAL=$(tput sgr0)
  fi
}

################################################################################
# Prints a given string to stoud using the specified formatting.
# -- Globals:
#  NORMAL - Reset formatting.
# -- Inputs:
#  text - Text to be colorized.
#  format... - List of color globals.
# -- Output: The formatted string.
################################################################################
format() {
  local text=$1
  shift
  local IFS=''
  printf "%s%s%s" "$*" "$text" "$NORMAL"
}

_init_formatting
