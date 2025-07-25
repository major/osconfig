#!/bin/bash
# Copyright 2019 Google Inc. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

function build_success() {
  echo "Build succeeded: $@"
  exit 0
}

function build_fail() {
  echo "Build failed: $@"
  exit 1
}

function exit_error() {
  build_fail "$0:$1 \"$BASH_COMMAND\" returned $?"
}

trap 'exit_error $LINENO' ERR

function install_go() {
  # Installs a specific version of go for compilation, since availability varies
  # across linux distributions. Needs curl and tar to be installed.
  local arch="amd64"
  if [[ `uname -m` == "aarch64" ]]; then
    arch="arm64"
  fi

  local GOLANG="go1.24.2.linux-${arch}.tar.gz"
  export GOPATH=/usr/share/gocode
  export GOCACHE=/tmp/.cache

  # Golang setup
  [[ -d /tmp/go ]] && rm -rf /tmp/go
  mkdir -p /tmp/go/
  curl -s "https://dl.google.com/go/${GOLANG}" -o /tmp/go/go.tar.gz
  tar -C /tmp/go/ --strip-components=1 -xf /tmp/go/go.tar.gz

  export PATH="/tmp/go/bin:${GOPATH}/bin:${PATH}"  # set path for whoever invokes this function.
  export GO=/tmp/go/bin/go  # reference this go explicitly.
}

function git_checkout() {
  # Checks out a repo at a specified commit or ref into a specified directory.

  BASE_REPO="$1"
  REPO="$2"
  PULL_REF="$3"

  # pull the repository from github - start
  mkdir -p $REPO
  cd $REPO
  git init

  # fetch only the branch that we want to build
  git_command="git fetch https://github.com/${BASE_REPO}/${REPO}.git ${PULL_REF:-"master"}"
  echo "Running ${git_command}"
  $git_command

  git checkout FETCH_HEAD
}

function try_command() {
  n=0
  while ! "$@"; do
    echo "try $n to run $@"
    if [[ n -gt 3 ]]; then
      return 1
    fi
    ((n++))
    sleep 5
  done
}
