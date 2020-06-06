#!/bin/bash
# Deno version management script
DENO_RELEASE_URL="https://api.github.com/repos/denoland/deno/releases?per_page=100"

DENOBREW_HOME="${HOME}/.denobrew"
DENOBREW_RELEASE="${DENOBREW_HOME}/releases"
DENOBREW_CACHE="${DENOBREW_HOME}/cache"

SUBCOMMANDS=(
  "ls"
  "ls-remote"
  "ls-all"
  "install"
  "uninstall"
  "use"
  "migrate-package-from"
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

DEPENDENCIES=(
  "unzip"
  "curl"
  "column"
  "tr"
  "grep"
  "cut"
  "perl"
)

for dep in ${DEPENDENCIES[@]}
do
  which ${dep} 2>&1 1>/dev/null || {
    echo_red "\`${dep}\` is not found in your machine.\nPlease install ${dep}." >&2
    exit 1
  }
done

function denobrew-ls-remote () {
  if [ -n "${DENOBREWSH_GITHUBAPI_CREDENTIAL}" ]; then
    releases_buf=$(curl -u "${DENOBREWSH_GITHUBAPI_CREDENTIAL}" -fsSL "${DENO_RELEASE_URL}")
  else
    releases_buf=$(curl -fsSL "${DENO_RELEASE_URL}" 2>/dev/null)
    if [ -z "${releases_buf}" ]; then
      echo_red "API rate limit might exceeded \nPlease set GitHub.com credential to \${DENOBREWSH_GITHUBAPI_CREDENTIAL}" >&2
      return
    fi
  fi
  installed=($(denobrew-ls --flat --decolorize ))
  v="$(deno --version 2>/dev/null | grep deno || echo)"
  v=v${v#deno }
  releases_buf=$(echo ${releases_buf} | tr "," "\n" | grep tag_name | cut -d \" -f 4)
  releases=()
  if [[ " $@ " =~ " --decolorize " ]]; then
    for r in ${releases_buf}
    do
      releases=("${releases[@]}" "${r}")
    done
  else
    for r in ${releases_buf}
    do
      if [ "${r}" = "${v}" ]; then
        releases=("${releases[@]}" "\e[36m${r}\e[m")
      elif [[ " ${installed[@]} " =~ " ${r} " ]]; then
        releases=("${releases[@]}" "\e[32m${r}\e[m")
      else
        releases=("${releases[@]}" "\e[37m${r}\e[m")
      fi
    done
  fi
  IFS=$'\n'
  if [[ " $@ " =~ " --flat " ]]; then
    echo -e "${releases[*]}"
  else
    echo -e "${releases[*]}" | column
  fi
}

function denobrew-ls () {
  bins=$(ls -r ${DENOBREW_RELEASE}/*/bin/deno 2>/dev/null)
  c="$(deno --version 2>/dev/null| grep deno || echo )"
  c=v${c#deno }
  installed=()
  for bin in ${bins}
  do
    v="$(${bin} --version | grep deno)"
    v=v${v#deno }
    e=${bin#${DENOBREW_RELEASE}/}
    e=${e%/bin/deno}
    if [ "${e}" != "${v}" ]; then continue; fi;

    if [[ " $@ " =~ " --decolorize " ]]; then
      installed=("${installed[@]}" "${v}")
    else
      if [ "${c}" = "${v}" ]; then
        installed=("${installed[@]}" "\e[36m${v}\e[m")
      else
        installed=("${installed[@]}" "\e[37m${v}\e[m")
      fi
    fi
  done
  IFS=$'\n'
  if [[ " $@ " =~ " --flat " ]]; then
    echo -e "${installed[*]}"
  else
    echo -e "${installed[*]}" | column
  fi
}

function denobrew-ls-all () {
  echo "Remote:"
  denobrew-ls-remote
  echo ""
  echo "Local:"
  denobrew-ls
}

function denobrew-install () {
  if [ -z "$1" ]; then
    echo_red "Please set version string (ex. \`v1.0.0\`)." >&2
    exit 1;
  fi
  deno_version=$(denobrew-ls-remote --flat --decolorize | grep -x "$1" || echo "")
  if [ -z "${deno_version}" ]; then
    echo_red "Deno \`$1\` is not found in Deno releases." >&2;
    echo_red "Please check released versions by \`$(basename $0) ls-remote\`." >&2
    exit 1;
  fi
  deno_version=$1
  DENO_INSTALL=${DENOBREW_RELEASE}/${deno_version}
  mkdir -p ${DENO_INSTALL}
  mkdir -p ${DENOBREW_CACHE}/${deno_version}
  curl -fsSL https://deno.land/x/install/install.sh | DENO_INSTALL=${DENO_INSTALL} sh -s ${deno_version} | head -n 3
  echo_blue "Please execute \`$(basename $0) use ${deno_version}\` for activating the version." >&2
}

function denobrew-migrate-package-from () {
  if [ -z "$1" ]; then
    echo_red "Please set version string (ex. \`v1.0.0\`)." >&2
    exit 1;
  fi
  deno_target_version=$(denobrew-ls --flat --decolorize | grep -x "$1" || echo "")
  if [ -z "${deno_target_version}" ]; then
    echo_red "Deno \`$1\` is not found in your machine." >&2
    exit 1;
  fi
  packages=$(ls ${DENOBREW_RELEASE}/${deno_target_version}/bin/ | grep -vx "deno")
  echo_blue "Found following package(s) in ${deno_target_version}:">&2
  echo_blue "${packages}" | perl -pe 's/^/ /' >&2
  echo >&2
  for pkg in ${packages}
  do
    cmd=$(cat "${DENOBREW_RELEASE}/${deno_target_version}/bin/${pkg}" | grep -v "#")
    cmd=${cmd//\"/}
    cmd=${cmd// run / install }
    cmd=${cmd// http/ -f -n ${pkg} http}
    cmd=${cmd%\$@}
    echo_blue "Installing ${pkg} ...">&2
    eval "${cmd%\$@} 2>/dev/null"
  done
}

function denobrew-use () {
  if [ -z "$1" ]; then
    echo_red "Please set version string (ex. \`v1.0.0\`)." >&2
    exit 1;
  fi
  deno_version=$(denobrew-ls --flat --decolorize | grep -x "$1" || echo "")
  if [ -z "${deno_version}" ]; then
    echo_red "Deno \`$1\` is not found in your machine." >&2
    echo_red "Please retry after executing following command." >&2
    echo_red "" >&2
    echo_red "  \`$(basename $0) install "$1"\`" >&2
    exit 1;
  fi
  c="$(deno --version 2>/dev/null| grep deno || echo )"
  c=${c#deno }

  deno_install=${DENO_INSTALL:-${HOME}/.deno}/bin
  unlink ${deno_install} 2>/dev/null || rm -rf ${deno_install} 2>/dev/null
  mkdir -p $(dirname ${deno_install})
  ln -s "${DENOBREW_RELEASE}/${deno_version}/bin" ${deno_install}

  which deno 2>&1 1>/dev/null || {
    echo_red "Please add \`${deno_version}\` to PATH and do again." >&2
    exit 1
  }
  deno_dir=$(deno info | grep DENO_DIR | cut -d " " -f 3)
  deno_dir=${deno_dir//\"/}
  unlink ${deno_dir} 2>/dev/null || rm -rf ${deno_dir} 2>/dev/null
  mkdir -p $(dirname ${deno_dir})
  ln -s "${DENOBREW_CACHE}/${deno_version}/" ${deno_dir}

  deno --version | perl -pe 's/^/ /' 2>/dev/null || echo_red "Please add \`${deno_install}\` to PATH." >&2
  if [[ " $@ " =~ " --with-migration " ]]; then
    echo 2>/dev/null
    denobrew-migrate-package-from "v${c}"
  fi
}

function denobrew-uninstall () {
  if [ -z "$1" ]; then
    echo_red "Please set version string (ex. \`v1.0.0\`)." >&2
    exit 1;
  fi
  deno_uninstall_version=$(denobrew-ls --flat --decolorize | grep -x "$1" || echo "")
  if [ -z "${deno_uninstall_version}" ]; then
    echo_red "Deno \`$1\` is not found in your machine." >&2
    exit 1;
  fi
  deno_uninstall_version=$1
  deno_current_version="$(deno --version | grep deno || echo)"
  deno_current_version=v${deno_current_version#deno }
  if [ "$1" = "${deno_current_version}" ]; then
    deno_dir=$(deno info | grep DENO_DIR | cut -d " " -f 3)
    deno_dir=${deno_dir//\"/}
    unlink ${deno_dir} 2>/dev/null || rm -rf ${deno_dir}
    unlink ${DENO_INSTALL:-${HOME}/.deno}/bin 2>/dev/null
  fi
  rm -rf "${DENOBREW_RELEASE}/${deno_uninstall_version}/"
  rm -rf "${DENOBREW_CACHE}/${deno_uninstall_version}/"
}

if [ -z "$1" ]; then
  source /dev/stdin <<< "$(curl -s https://raw.githubusercontent.com/l3laze/sind/master/sind.sh)"
  subCmd=$(sind "Choose sub-command:" ${SUBCOMMANDS[@]})
  echo "----"
  if [[ " use uninstall migrate-package-from " =~ " ${subCmd} " ]]; then
    echo "installed versions:"
    denobrew-ls >&2
    echo ""
    read -p "version: " version
  elif [ "${subCmd}" = "install" ]; then
    echo "released versions:"
    denobrew-ls-remote >&2
    echo ""
    read -p "version: " version
  fi
  subCmd=("${subCmd[@]}" ${version})

else
  subCmd=($@)
fi

if [[ ! " ${SUBCOMMANDS[@]} " =~ " ${subCmd[0]} " ]]; then
  echo_red "Sub command \`$1\` is not available." >&2
  exit 1
fi

denobrew-"${subCmd[@]}"

