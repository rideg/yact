#!/usr/bin/env bash

################################################################################
# Reads the current file format version.
# -- Globals:
#  YACT_DIR - Working directory for YACT.
# -- Input: None
# -- Output: The version (or 0 if version is not specified)
################################################################################
read_version() {
  __='0000'
  [[ -f "$YACT_DIR/version" ]] && read -r __ <"$YACT_DIR/version"
  let __="10#$__"
}

################################################################################
# Reads patch serial numbers.
# -- Globals:
#  YACT_PATCH_DIR - Directory for storage patches.
# -- Input: None
# -- Output:
#  PATCHES - The map of serial number to patch file.
################################################################################
read_patches() {
 export PATCHES
 let prefix=${#YACT_PATCH_DIR}+2
 for file in $YACT_PATCH_DIR/*.patch.bash; do
   # If directory does not contain such files
   [[ "$file" = "$YACT_PATCH_DIR/*.patch.bash" ]] && break
   let version="10#${file:$prefix:4}"
   PATCHES[$version]="$file"
 done
}

################################################################################
# Checks the current storage version against the desired version and if needed
# executes the actual sotrage migration.
# -- Globals:
#  PATCHES - the list of the available patches.
# -- Input: None
# -- Output: None
################################################################################
migrate_storage() {
  read_version
  read_patches
  let next_version=__+1
  if [[ $next_version -le ${#PATCHES[@]} ]]; then
    execute_migration "$__"
  else
    echo "Storage is up to date."
  fi
  exit_ 0
}

################################################################################
# Executes the storage migation: applies patches one by one. If something goes
# wrong it tries to roll back.
# -- Globals:
#  PATCHES - The list of the available patches.
#  RED - Color red for formatting.
#  GREEN - Color green for formatting.
#  NORMAL - Reset console text formatting.
#  YACT_DIR - Working directory for YACT.
#  STORAGE_DIR - storage
# -- Input:
#  current_version - Current storage version.
# -- Output: None
################################################################################
execute_migration() {
  echo "Storage migration is needed."
  echo "Current storage version is: $1."
  echo "Desired version is: ${#PATCHES[@]}."

  read_to -v dt date_time
  read_to -v tmpdir mktemp -d

  # shellcheck disable=SC2154
  local archive=$tmpdir/backup-${dt}.tar.gz
  tar -czf "$archive" -C "${YACT_DIR%/*}" "${YACT_DIR##*/}" >/dev/null || \
    fatal "Could not create backup."

  let next_version=$1+1
  export error_message
  for ((i=next_version; i<=${#PATCHES[@]}; i++)); do
    # shellcheck disable=SC1090
    . "${PATCHES[$i]}"
    printf "Applying patch: '%s'" "${PATCHES[$i]}"
    if __do_migrate; then
      echo "${GREEN}done${NORMAL}"
    else
      echo "${RED}failed${NORMAL}"
      break
    fi
  done

  if [[ -n "$error_message" ]]; then
    echo "Could not migrate storage: $error_message"
    rm -rf "$YACT_DIR" > /dev/null
    tar -xzf "$archive" -C "${YACT_DIR%/*}" || \
      fatal "Could not roll-back. However you can find your original files \
             in '$archive'."
  else
   echo "${#PATCHES[@]}" > "$YACT_DIR/version"
   [[ -d $YACT_DIR/backup ]] || mkdir -p "$YACT_DIR"/backup
   cp "$archive" "$YACT_DIR"/backup
   rm -rf "$tmpdir"
   echo "Storage migration is done."
  fi
}

