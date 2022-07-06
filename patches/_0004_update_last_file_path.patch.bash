#!/usr/bin/env bash

################################################################################
# Use absolute path in .last file.
# -- Globals:
# RUN - runtime directory.
# STORAGE_DIR - file storage directory.
# TODO_FILE - latest todo file.
# -- Input: None
# -- Output: None
################################################################################
__do_migrate() {
	if [[ -f "$RUN/.last" ]]; then
		. "$RUN/.last"
    echo "${STORAGE_DIR}/{$TODO_FILE}" > "$RUN/.last"
	fi
}

