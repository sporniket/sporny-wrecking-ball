#!/usr/bin/env bash
CMD_WORKDIR=$(cd $(dirname $0) && pwd)
FILE_FOLDERS_MK="${1}/folders.local.mk"
FILE_ENV_LOCAL="${1}/environment.local"
setup_wizz_help() {
  cli_name=${0##*/}
  echo -e "
\e[90m$cli_name\e[0m
\e[96mHelper to setup the other commands of the CLI.\e[0m
"
}

require() {
  ### checks that a command exists or print a message
  # $1 : command to check
  # $2 : component name to give to install
  if ! command -v ${1} &> /dev/null
  then
    log_error "Command '${1}' not found. Use 'ap install ${2}'."
  fi
}

setup_wizz_help

log_info "Checking for required commands..."

CHECK_COMMAND="$(require hatari)"
CHECK_COMMAND="${CHECK_COMMAND}$(require vasmm68k_mot vasm)"

if [[ ${CHECK_COMMAND} ]]; then
  echo -e "${CHECK_COMMAND}"
  log_fatal "Aborting setup"
  exit 1
fi
touch "${FILE_FOLDERS_MK}"

install_dir="swb"
log_ok "\e[92m${install_dir}\e[0m will be the folder name in the GEMDOS emulated drive"

[[ ! -d "${1}/build/${install_dir}" ]] && mkdir -p ${1}/build/${install_dir} && log_ok "Created install folder '${1}/build/${install_dir}'"

log_info "Creating ${FILE_FOLDERS_MK}..."
BACKSLASH="\\\\\\"
echo -e "
INSTALLDIR = ${1}/build/${install_dir}
INCLUDEDIR_COMMONS = ${1}/00_commons
" > "${FILE_FOLDERS_MK}"
cat ${FILE_FOLDERS_MK}
log_info "Creating ${FILE_ENV_LOCAL}..."
echo -e "
# linux pathes
export GEMDOS_DRIVE=\"${1}/build\"
export INSTALL_FOLDER=\"${1}/build/${install_dir}\"

# variables for hatari
export AUTORUN_PREFIX=\"C:${BACKSLASH}${install_dir^^}${BACKSLASH}\"
" > "${FILE_ENV_LOCAL}"
cat ${FILE_ENV_LOCAL}
. ${FILE_ENV_LOCAL}

log_ok "Done"
