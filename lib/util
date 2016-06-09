
timestamp() {
  date +"%s"
}

exit_() {
  rm -f .changed &> /dev/null
  popd &> /dev/null
  exit $1
}

fatal() {
 printf "$1\n"
 exit_ 1
}

