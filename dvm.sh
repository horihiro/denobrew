#!/bin/bash
# Deno version management script

DENO_RELEASE_URL="https://api.github.com/repos/denoland/deno/releases"

DVM_HOME="${HOME}/.dvm.sh"
DVM_RELEASE="${DVM_HOME}/releases"
DVM_CACHE="${DVM_HOME}/cache"

SUBCOMMANDS=(
  "ls"
  "ls-remote"
  "install"
  "uninstall"
  "use"
)

function echo_cyan () {
  echo -e "\e[36m$1\e[m"
}

function echo_purple () {
  echo -e "\e[35m$1\e[m"
}

function echo_blue () {
  echo -e "\e[34m$1\e[m"
}

function echo_yellow () {
  echo -e "\e[33m$1\e[m"
}

function echo_green () {
  echo -e "\e[32m$1\e[m"
}

function echo_red () {
  echo -e "\e[31m$1\e[m"
}

which curl 2>&1 1>/dev/null || {
  echo_red "\`curl\` is not found in your machine.\nPlease install curl." >&2
  exit 1
}
which jq 2>&1 1>/dev/null || {
  echo_red "\`jq\` is not found in your machine.\nPlease install jq." >&2
  exit 1
}

function dvm-ls-remote () {
  if [ -n "${DVMSH_GITHUBAPI_CREDENTIAL}" ]; then
    curl -u "${DVMSH_GITHUBAPI_CREDENTIAL}" -fsSL "${DENO_RELEASE_URL}" | jq -r ".[].name"
  else
    release=$(curl -fsSL "${DENO_RELEASE_URL}" 2>/dev/null)
    if [ -z "${releases}" ]; then
      echo_red "API rate limit might exceeded \nPlease set GitHub.com credential to \${DVMSH_GITHUBAPI_CREDENTIAL}" >&2
    fi
    echo ${releases} | jq -r ".[].name"
  fi
}

function dvm-ls () {
  bins=$(ls ${DVM_RELEASE}/*/bin/deno 2>/dev/null)
  for bin in ${bins}
  do
    v="$(${bin} --version | grep deno)"
    v=v${v#deno }
    e=${bin#${DVM_RELEASE}/}
    e=${e%/bin/deno}
    if [ "${e}" = ${v} ]; then
      echo ${v}
    fi
  done
}

function dvm-install () {
  if [ -z "$1" ]; then
    echo_red "Please set version string (ex. \`v1.0.0\`)." >&2
    exit 1;
  fi
  deno_version=$(dvm-ls-remote | grep -x "$1" || echo "")
  if [ "${deno_version}" != "$1" ]; then
    echo_red "Deno \`$1\` is not found in Deno releases." >&2;
    echo_red "Please check released versions by \`$(basename $0) ls-remote\`." >&2
    exit 1;
  fi
  DENO_INSTALL=${DVM_RELEASE}/${deno_version}
  mkdir -p ${DENO_INSTALL}
  mkdir -p ${DVM_CACHE}/${deno_version}
  curl -fsSL https://deno.land/x/install/install.sh | DENO_INSTALL=${DENO_INSTALL} sh -s ${deno_version} | head -n 3
  echo_blue "Please execute \`$(basename $0) use ${deno_version}\` for activating the version." >&2
}

function dvm-use () {
  if [ -z "$1" ]; then
    echo_red "Please set version string (ex. \`v1.0.0\`)." >&2
    exit 1;
  fi
  deno_version=$(dvm-ls | grep -x "$1" || echo "")
  if [ "${deno_version}" != "$1" ]; then
    echo_red "Deno \`$1\` is not found in your machine." >&2
    echo_red "Please retry after executing following command." >&2
    echo_red "" >&2
    echo_red "  \`$(basename $0) install "$1"\`" >&2
    exit 1;
  fi
  deno_install=${DENO_INSTALL:-${HOME}/.deno}/bin
  unlink ${deno_install} 2>/dev/null
  ln -s "${DVM_RELEASE}/${deno_version}/bin" ${deno_install}

  deno_dir=$(deno info | grep DENO_DIR | cut -d " " -f 3)
  deno_dir=${deno_dir//\"/}
  unlink ${deno_dir} || rm -rf ${deno_dir} 2>/dev/null
  mkdir -p $(dirname ${deno_dir})
  ln -s "${DVM_CACHE}/${deno_version}/" ${deno_dir}

  deno --version 2>/dev/null || echo_red "Please add \`${deno_install}\` to PATH." >&2
}

function dvm-uninstall () {
  if [ -z "$1" ]; then
    echo_red "Please set version string (ex. \`v1.0.0\`)." >&2
    exit 1;
  fi
  deno_uninstall_version=$(dvm-ls | grep -x "$1" || echo "")
  if [ "${deno_uninstall_version}" != "$1" ]; then
    echo_red "Deno \`$1\` is not found in your machine." >&2
    exit 1;
  fi
  deno_current_version="$(deno --version | grep deno)"
  deno_current_version=v${deno_current_version#deno }
  if [ "${deno_uninstall_version}" = "${deno_current_version}" ]; then
    deno_dir=$(deno info | grep DENO_DIR | cut -d " " -f 3)
    deno_dir=${deno_dir//\"/}
    unlink ${deno_dir} || rm -rf ${deno_dir}
    unlink ${DENO_INSTALL:-${HOME}/.deno}/bin
  fi
  rm -rf "${DVM_RELEASE}/${deno_uninstall_version}/"
  rm -rf "${DVM_CACHE}/${deno_uninstall_version}/"
}

if [ -z "$1" ]; then
  source /dev/stdin <<< "$(curl -s https://raw.githubusercontent.com/l3laze/sind/master/sind.sh)"
  userChoice=$(sind "Choose sub-command:" ${SUBCOMMANDS[@]})
  subCmd=(${SUBCOMMANDS[userChoice]})
else
  subCmd=($@)
fi

if ! $(echo ${SUBCOMMANDS[@]} | grep -q -w ${subCmd[0]} || echo false) ; then
  echo_red "Sub command \`$1\` is not available." >&2
  exit 1
fi

dvm-"${subCmd[@]}"

# case "$subCmd" in
#   "ls-remote") ls-remote;;
#   1) echo "selected No";;
#   2) echo "selected Batman";;
#   3) echo "selected Cancel";;
# esac
