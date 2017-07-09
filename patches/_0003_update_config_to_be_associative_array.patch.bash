
#!/usr/bin/env bash

################################################################################
# Updates config to use associative array.
# -- Globals:
#  YACT_DIR - Working directory for YACT.
# -- Input: None
# -- Output: None
################################################################################
__do_migrate() {
  local cfg=$YACT_DIR/config
  printf 'CONFIG[hide_done]=%d\n' "${HIDE_DONE-0}" > "$cfg"
  printf 'CONFIG[line_length]=%d\n' "${LINE_LENGTH-70}" >> "$cfg"
  printf 'CONFIG[use_formatting]=%d\n' "${USE_FORMATTING-1}" >> "$cfg"
}

