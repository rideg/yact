#!/bin/sh

has_colors=0

if [ $(tput colors) -gt 2 ] 2> /dev/null; then
  has_colors=1
fi

if [ $has_colors -eq 1 ]; then
  black=$(tput setaf 0)
  red=$(tput setaf 1)
  green=$(tput setaf 2)
  yellow=$(tput setaf 3)
  blue=$(tput setaf 4)
  magenta=$(tput setaf 5)
  cyan=$(tput setaf 6)
  white=$(tput setaf 7)
  bold=$(tput bold)
  normal=$(tput sgr0)
  reverse=$(tput smso)
  underline=$(tput smul)

  bg_black=$(tput setab 0)
  bg_red=$(tput setab 1)
  bg_green=$(tput setab 2)
  bg_yellow=$(tput setab 3)
  bg_blue=$(tput setab 4)
  bg_magenta=$(tput setab 5)
  bg_cyan=$(tput setab 6)
  bg_white=$(tput setab 7)
fi

color() {
 local word=$1
 shift
 local IFS=''
 printf "$*${word}${normal}"
}

