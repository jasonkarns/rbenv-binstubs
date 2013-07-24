#!/usr/bin/env bats

load test_helper

create_executable() {
  local bin="${RBENV_ROOT}/versions/${1}/bin"
  mkdir -p "$bin"
  touch "${bin}/$2"
  chmod +x "${bin}/$2"
}

@test "creates shims for binstubs" {
  create_Gemfile
  create_binstub "jimmy"
  create_binstub "hello"

  assert [ ! -e "${RBENV_ROOT}/shims/hello" ]
  assert [ ! -e "${RBENV_ROOT}/shims/jimmy" ]
  assert [ ! -e "${RBENV_ROOT}/bundles" ]

  (
  cd $RAILS_ROOT
  run rbenv-rehash
  assert_success ""
  )

  assert [ -e "${RBENV_ROOT}/bundles" ]

  run cat "${RBENV_ROOT}/bundles"
  assert_success "$RAILS_ROOT"

  run ls "${RBENV_ROOT}/shims"
  assert_success
  assert_output <<OUT
hello
jimmy
OUT

}

@test "removes shims and forgets railsapp if Gemfile is removed" {
  create_Gemfile
  create_binstub "fred"

  (
  cd $RAILS_ROOT
  run rbenv-rehash
  #assert_success ""
  )

  assert [ -s "${RBENV_ROOT}/bundles" ]

  assert [ -e "${RBENV_ROOT}/shims/fred" ]

  (
  cd $RAILS_ROOT
  rm -f Gemfile
  run rbenv-rehash
  echo " ================== "
  assert_success ""
  echo " =========2========= "
  )

  assert [ ! -e "${RBENV_ROOT}/shims/fred" ]

  run cat "${RBENV_ROOT}/bundles"
  assert_success ""

}


@test "removes shims if binstub is removed" {
  create_Gemfile
  create_binstub "fred"

  (
  cd $RAILS_ROOT
  run rbenv-rehash
  assert_success ""
  )

  assert [ -s "${RBENV_ROOT}/bundles" ]

  assert [ -e "${RBENV_ROOT}/shims/fred" ]

  (
  cd $RAILS_ROOT
  rm -f bin/fred
  run rbenv-rehash
  assert_success ""
  )

  run cat "${RBENV_ROOT}/bundles"
  assert_success "$RAILS_ROOT"

  assert [ ! -e "${RBENV_ROOT}/shims/fred" ]
}



# Standard tests

@test "empty rehash" {
  assert [ ! -d "${RBENV_ROOT}/shims" ]
  run rbenv-rehash
  assert_success ""
  assert [ -d "${RBENV_ROOT}/shims" ]
  rmdir "${RBENV_ROOT}/shims"
}

@test "non-writable shims directory" {
  mkdir -p "${RBENV_ROOT}/shims"
  chmod -w "${RBENV_ROOT}/shims"
  run rbenv-rehash
  assert_failure "rbenv: cannot rehash: ${RBENV_ROOT}/shims isn't writable"
}

@test "rehash in progress" {
  mkdir -p "${RBENV_ROOT}/shims"
  touch "${RBENV_ROOT}/shims/.rbenv-shim"
  run rbenv-rehash
  assert_failure "rbenv: cannot rehash: ${RBENV_ROOT}/shims/.rbenv-shim exists"
}

@test "creates shims" {
  create_executable "1.8" "ruby"
  create_executable "1.8" "rake"
  create_executable "2.0" "ruby"
  create_executable "2.0" "rspec"

  assert [ ! -e "${RBENV_ROOT}/shims/ruby" ]
  assert [ ! -e "${RBENV_ROOT}/shims/rake" ]
  assert [ ! -e "${RBENV_ROOT}/shims/rspec" ]

  run rbenv-rehash
  assert_success ""

  run ls "${RBENV_ROOT}/shims"
  assert_success
  assert_output <<OUT
rake
rspec
ruby
OUT
}

@test "carries original IFS within hooks" {
  hook_path="${RBENV_TEST_DIR}/rbenv.d"
  mkdir -p "${hook_path}/rehash"
  cat > "${hook_path}/rehash/hello.bash" <<SH
hellos=(\$(printf "hello\\tugly world\\nagain"))
echo HELLO="\$(printf ":%s" "\${hellos[@]}")"
exit
SH

  RBENV_HOOK_PATH="$hook_path" IFS=$' \t\n' run rbenv-rehash
  assert_success
  assert_output "HELLO=:hello:ugly:world:again"
}
