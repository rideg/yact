#!/usr/bin/env bash

################################################################################
# Adds 0; prefix to all tasks to indicate task type.
# -- Globals:
#  YACT_DIR - Working directory for YACT.
#  HEADER - Current todo's header.
#  TASKS - Current todo's tasks array.
# -- Input: None
# -- Output: None
################################################################################
__do_migrate() {
 for file in "$YACT_DIR"/*.txt; do
   read_task_file "$file"
   printf "%s\n\n" "$HEADER" > "$file"
   printf "0;%s\n" "${TASKS[@]}" >> "$file"
 done
}

