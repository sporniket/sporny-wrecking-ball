#!/usr/bin/env bash
CMD_WORKDIR=$(cd $(dirname $0) && pwd)

echo $CMD_WORKDIR
setup_wizz_help() {
  cli_name=${0##*/}
  echo -e "
\e[90m$cli_name\e[0m
\e[96mSetting up the installation path for build scripts and makefiles.\e[0m

\e[96mUsage:\e[0m $cli_name \e[93m[project_folder]\e[0m
"
  exit 1
}

log_trace "project_folder = ${1}"
echo -e "${LOG_TRACE} ${1}"
touch "${1}/install_dir.mk"
echo "INSTALLDIR = something"
setup_wizz_help
