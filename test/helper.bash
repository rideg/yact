#!/usr/bin/env bash

################################################################################
# Configures environment for test run:
#  > Configures YACT exutable
#  > Creates sandbox directory for YACT.
#  > Creates directory for fake commands and configures PATH.
# -- Globals:
#  BATS_TEST_DIRNAME - Directory where the test file is.
#  BATS_TMPDIR - Temproray directory provided by bats.
#  YACT_TEST_DIR - Tmp directory for test run.
#  YACT_DIR - Working directory for YACT.
#  EXECUTABLE_DIR - Directory for fake tools.
#  PATH - System path.
#  YACT - YACT executable.
# -- Input: None
# -- Output: None
################################################################################
_setup_yact() {
   export YACT="${BATS_TEST_DIRNAME}"/../bin/yact 
   export YACT_TEST_DIR="${BATS_TMPDIR}"/yact-test
   export YACT_DIR="${YACT_TEST_DIR}"/run
   export EXECUTABLE_DIR="${YACT_TEST_DIR}"/bin
   mkdir -p "${YACT_DIR}"
   mkdir -p "${EXECUTABLE_DIR}"
   export PATH="${EXECUTABLE_DIR}:${PATH}"
}

################################################################################
# Turns off console formatting for easy output verification.
# -- Globals:
#  YACT_DIR - Working directory for YACT.
# -- Input: None
# -- Output: None
################################################################################
_set_no_color() {
    echo "USE_FORMATTING=0" >> "${YACT_DIR}"/config
}


################################################################################
# Cleans the test temp direcotry.
# -- Globals:
#  YACT_TEST_DIR - Tmp directory for test run.
# -- Input: None
# -- Output: None
################################################################################
_clean_test_dir() {
    rm -rf "${YACT_TEST_DIR}"
}

################################################################################
# Creates a fake command with a specified response.
# -- Globals:
#  EXECUTABLE_DIR - Directory for fake tools.
# -- Input:
#  tool_name - The name of the command to faked.
#  answer - The shell commands to be executed when calling.
# -- Output: None
################################################################################
_spy_tool() {
    local tool_name="$1"
    local answer="$2"
    echo -e "#!/usr/bin/env bash\n${answer}" > "${EXECUTABLE_DIR}/${tool_name}"
    chmod +x "${EXECUTABLE_DIR}/${tool_name}"
}
