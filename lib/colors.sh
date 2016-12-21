#!/usr/bin/env bash
# YACT - Yet Another Command line TODO
# Copyright(c) 2016 Sandor Rideg
# MIT Licensed

init_colors() {
  if [[ "$(tput colors)" -gt 2 && $USE_COLORS -eq 1 ]] 2> /dev/null; then
    export BLACK RED GREEN YELLOW BLUE MAGENTA CYAN WHITE BOLD REVERSE UNDERLINE \
          BG_BLACK BG_RED BG_GREEN BG_YELLOW BG_BLUE BG_MAGENTA BG_CYAN BG_WHITE \
          NORMAL
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

color() {
 local word=$1
 shift
 local IFS=''
 printf "%s%s%s" "$*" "$word" "$NORMAL"
}

init_colors
