#!/usr/bin/env bash

################################################################################
# Initialize formatting globals for colorized input if colors are enabled.
# -- Globals:
#  CONFIG - configuration
# -- Input: None
# -- Output: None
################################################################################
yact::format::init() {
  if [[ ${CONFIG[use_formatting]} -eq 1 ]]; then
    export BLACK RED GREEN YELLOW BLUE MAGENTA CYAN WHITE BOLD REVERSE \
      UNDERLINE BG_BLACK BG_RED BG_GREEN BG_YELLOW BG_BLUE BG_MAGENTA \
      BG_CYAN BG_WHITE NORMAL
    BLACK=$'\e[30m'
    RED=$'\e[31m'
    GREEN=$'\e[32m'
    YELLOW=$'\e[33m'
    BLUE=$'\e[34m'
    MAGENTA=$'\e[35m'
    CYAN=$'\e[36m'
    WHITE=$'\e[97m'
    BOLD=$'\e[1m'
    REVERSE=$'\e[7m'
    UNDERLINE=$'\e[4m'

    BG_BLACK=$'\e[40m'
    BG_RED=$'\e[41m'
    BG_GREEN=$'\e[42m'
    BG_YELLOW=$'\e[43m'
    BG_BLUE=$'\e[44m'
    BG_MAGENTA=$'\e[45m'
    BG_CYAN=$'\e[46m'
    BG_WHITE=$'\e[107m'
    NORMAL=$'\e[0m'
    yact::util::read_to -v COLUMNS tput cols
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
yact::format::format() {
  local text=$1
  shift
  export __="$*$text$NORMAL"
}
