#!/usr/bin/env bash
CMD_WORKDIR=$(cd $(dirname $0) && pwd)
FILE_INSTALL_DIR_MK="${1}/install_dir.mk"
FILE_ENV_LOCAL="${1}/environment.local"
setup_wizz_help() {
  cli_name=${0##*/}
  echo -e "
\e[90m$cli_name\e[0m
\e[96mHelper to setup the other commands of the CLI.\e[0m
"
}

setup_wizz_help
touch "${FILE_INSTALL_DIR_MK}"
echo -n -e "\e[96mName of the project folder in the GEMDOS drive : \e[0m"
read install_dir

[[ ! -d "${1}/build/${install_dir}" ]] && mkdir -p ${1}/build/${install_dir} && log_ok "Created install folder '${1}/build/${install_dir}'"

log_info "Creating ${FILE_INSTALL_DIR_MK}..."
echo -e "INSTALLDIR = ${1}/build/${install_dir}" > "${FILE_INSTALL_DIR_MK}"
cat ${FILE_INSTALL_DIR_MK}
log_info "Creating ${FILE_ENV_LOCAL}..."
echo -e "export GEMDOS_DRIVE=\"${1}/build\"" > "${FILE_ENV_LOCAL}"
echo -e "export AUTORUN_FOLDER=\"${1}/build/${install_dir}\"" >> "${FILE_ENV_LOCAL}"
cat ${FILE_ENV_LOCAL}
. ${FILE_ENV_LOCAL}

log_ok "Done"
echo "---"
