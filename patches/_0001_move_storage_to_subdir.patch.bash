#!/usr/bin/env bash

################################################################################
# Moves all lists, config, and version to YACT_DIR/storage
# -- Globals:
#  YACT_DIR - Working directory for YACT.
# -- Input: None
# -- Output: None
################################################################################
__do_migrate() {
  mkdir -p "$YACT_DIR"/storage
  mkdir -p "$YACT_DIR"/backup

  mv "$YACT_DIR"/*.txt "$YACT_DIR"/storage
  [[ -f "$YACT_DIR"/.pipe ]] && mv "$YACT_DIR"/.pipe "$YACT_DIR/.run"
  [[ -f "$YACT_DIR"/.last ]] && mv "$YACT_DIR"/.last "$YACT_DIR/.run"
  [[ -f "$YACT_DIR"/.changed ]] && mv "$YACT_DIR"/.changed "$YACT_DIR/.run"
}

