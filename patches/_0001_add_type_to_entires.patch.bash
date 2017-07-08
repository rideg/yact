#!/usr/bin/env bash

################################################################################
# Adds 0; prefix to all tasks to indicate task type.
# -- Globals:
#  STORAGE_DIR - storage
#  HEADER - Current todo's header.
#  TASKS - Current todo's tasks array.
# -- Input: None
# -- Output: None
################################################################################
__do_migrate() {
 for file in "$STORAGE_DIR"/*.txt; do
   read_task_file "$file"
   printf "%s\n\n" "$HEADER" > "$file"
   printf "0;%s\n" "${TASKS[@]}" >> "$file"
 done
}

