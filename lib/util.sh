#!/bin/bash

is_true() {
  test $1 -eq 1
}

timestamp() {
  date +"%s"
}

exit_() {
  rm -f $YACT_DIR/.run/* &> /dev/null
  popd &> /dev/null
  exit $1
}

fatal() {
 printf "$1\n"
 exit_ 1
}

