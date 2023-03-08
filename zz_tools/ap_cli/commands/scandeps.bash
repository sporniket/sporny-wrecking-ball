#!/usr/bin/env bash
DIR_BASE="$(pwd)"
DIR_COMMONS_MACROS="${DIR_BASE}/00_commons/macros"
DIR_COMMONS_LIBS="${DIR_BASE}/00_commons/libs"
DIR_APP_WRECKING_BALLS="${DIR_BASE}/10_wrecking_ball"
DIR_APP_SHEET_EXTRACTOR="${DIR_BASE}/20_sheet_extractor"
FILE_TARGET="dependencies.local.mk"

scandeps_help() {
  cli_name=${0##*/}
  echo -e "
\e[90m$cli_name\e[0m
\e[96mRegroup source files into lists for the makefiles.\e[0m
"
}

scan_dependencies() {
  ### Scan only for files directly inside this folder and outputs the list as a makefile variable
  # $1 : variable name
  # $2 : folder name
  # $3 : file filter
  varname="$1"
  folder="$2"
  names="$3"
  echo -e "${varname} = \\"
  find ${folder} -maxdepth 1 -name "${names}" -type f -exec echo {} " \\" \;
  echo
}

scan_dependencies_deeply() {
  ### outputs a list of files as a makefile variable
  # $1 : variable name
  # $2 : folder name
  # $3 : file filter (eg "*.s")
  varname="$1"
  folder="$2"
  names="$3"
  echo -e "${varname} = \\"
  find ${folder} -name "${names}" -type f -exec echo {} " \\" \;
  echo
}

scan_project() {
  ### scan a source program folder, expecting some optionnal subfolders to be there.
  # $1 : path of the program folder.
  log_info "Scanning ${1}..."
  cd "${1}"
  scan_dependencies "SRCS" "." "*.s" > "${FILE_TARGET}"
  if [[ -d "./includes" ]]; then
    scan_dependencies_deeply "INCLUDES" "./includes" "*.s" >> "${FILE_TARGET}"
  fi
  if [[ -d "./assets" ]]; then
    scan_dependencies_deeply "ASSETS" "./assets" "*" >> "${FILE_TARGET}"
  fi
  cd ..
}

scandeps_help
log_info "Scanning commons dependencies..."
scan_dependencies_deeply "COMMONS_MACROS" "${DIR_COMMONS_MACROS}" "*.s" > "${FILE_TARGET}"
scan_dependencies_deeply "COMMONS_LIBS" "${DIR_COMMONS_LIBS}" "*.s" >> "${FILE_TARGET}"

for prj in $(ls -d [1-9][0-9]_*); do
  scan_project "${prj}"
done
