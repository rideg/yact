#!/usr/bin/env bats

load 'load'

setup() {
   export YACT="$BATS_TEST_DIRNAME"/../bin/yact 
   export YACT_DIR=/tmp/yact-test
   mkdir -p "$YACT_DIR"
}

teardown() {
    rm -rf "$YACT_DIR"
}

@test "Should show message if there is not list defined" {
    # when
    run $YACT -l
    # then
    assert_output "No todo list has been selected, please select/create one."
}
