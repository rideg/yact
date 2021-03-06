#!/usr/bin/env bats

load 'load'
load 'helper'

setup() {
  _setup_yact
  _set_no_color
  mkdir -p "$YACT_STORAGE_DIR"
}

teardown() {
  _clean_test_dir
  _clean_patch_dir
}

@test "migration - no need for it" {
  # when
  run $YACT -a migrate 
 
  # then
  assert_output -p  "Storage is up to date."
}

@test "migration - executes patches" {
 # given
 _create_patch 1 "printf 'patch 0001\n'"
 _create_patch 2 "printf 'patch 0002\n'"
 _create_patch 3 "printf 'patch 0003\n'"
 # and
 local dt='2017-03-17_120530'
 _spy_tool date "printf '${dt}'"

 # when
 run $YACT -a migrate

 # then notifies migration is required 
 assert_output -p 'Storage migration is needed.'
 assert_output -p 'Current storage version is: 0.'
 assert_output -p 'Desired version is: 3'
 # and executes patches
 assert_output -p 'patch 0001'
 assert_output -p 'patch 0002'
 assert_output -p 'patch 0003'
 # and creates backup 
 assert [ -f $YACT_DIR/backup/backup-${dt}.tar.gz ]
}

@test "migration - adds file type patch" {
  # given
  _create_patch 1 
  cp patches/_0002_add_type_to_entires.patch.bash \
     "$YACT_PATCH_DIR"
  # and create a new todo 
  file="${YACT_STORAGE_DIR}/_1234567890.txt"

  (cat <<-'EOF'
			This is a todo

			This is a task;1
			This is another task;0
	EOF
  ) > "$file"
  
  # when
  run $YACT -a migrate

  # then
  readarray -t __ < "$file"
  assert [ "${__[2]}" == "0;This is a task;1" ]
  assert [ "${__[3]}" == "0;This is another task;0" ]
  assert [ -f "${YACT_DIR}/version" ]
  readarray -t __ < "${YACT_DIR}/version"
  assert [ "${__[0]}" == "2" ]
}

