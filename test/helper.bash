#!/usr/bin/env bash

_setup_yact() {
   export YACT="${BATS_TEST_DIRNAME}"/../bin/yact 
   export YACT_TEST_DIR="${BATS_TMPDIR}"/yact-test
   export YACT_DIR="${YACT_TEST_DIR}"/run
   export EXECUTABLE_DIR="${YACT_TEST_DIR}"/bin
   mkdir -p "${YACT_DIR}"
   mkdir -p "${EXECUTABLE_DIR}"
   export PATH="${EXECUTABLE_DIR}:${PATH}"
}

_clean_test_dir() {
    rm -rf "${YACT_TEST_DIR}"
}

_spy_tool() {
    echo -e "#!/usr/bin/env bash\n printf '%s' '$2'" > "${EXECUTABLE_DIR}/$1"
    chmod +x "${EXECUTABLE_DIR}"/"$1"
}