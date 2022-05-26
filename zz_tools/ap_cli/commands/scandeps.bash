#!/usr/bin/env bash
DIR_BASE="$(pwd)"
DIR_COMMONS_MACROS="${DIR_BASE}/00_commons/macros"
DIR_COMMONS_LIBS="${DIR_BASE}/00_commons/libs"
DIR_APP_WRECKING_BALLS="${DIR_BASE}/10_wrecking_ball"
DIR_APP_SHEET_EXTRACTOR="${DIR_BASE}/20_sheet_extractor"

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

scandeps_help
log_info "Scanning commons dependencies..."
scan_dependencies_deeply "COMMONS_MACROS" "${DIR_COMMONS_MACROS}" "*.s"
scan_dependencies_deeply "COMMONS_LIBS" "${DIR_COMMONS_LIBS}" "*.s"

log_info "Scanning ${DIR_APP_WRECKING_BALLS}..."
cd "${DIR_APP_WRECKING_BALLS}"
scan_dependencies "SRCS" "." "*.s"
scan_dependencies_deeply "INCLUDES" "./includes" "*.s"
scan_dependencies_deeply "ASSETS" "./assets" "*"
cd ..

log_info "Scanning ${DIR_APP_SHEET_EXTRACTOR}..."
cd "${DIR_APP_SHEET_EXTRACTOR}"
scan_dependencies "SRCS" "." "*.s"
#scan_dependencies_deeply "INCLUDES" "./includes" "*.s"
scan_dependencies_deeply "ASSETS" "./assets" "*"
cd ..
