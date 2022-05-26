#!/usr/bin/env bash
BASEDIR="$(pwd)"
TOOLS_DIR="${BASEDIR}/zz_tools"

install_help() {
  cli_name=${0##*/}
  echo -e "
\e[90m${cli_name}\e[0m
Install some required commands for building and running this project.

\e[96mUsage:\e[0m ${cli_name} \e[93m[component]\e[0m
\e[96mGoals:\e[0m
  \e[93mvasm\e[0m      VASM, a portable and retargetable assembler.
  \e[93mhatari\e[0m    Hatari, an Atari ST/STE/TT/Falcon emulator.
  \e[93m*\e[0m         Help
"
  exit 1
}

install_vasm () {
  RETURN_DIR="$(pwd)"
  BINDIR="${TOOLS_DIR}/bin"
  [ ! -d "${BINDIR}" ] && log_info "Make directory '${BINDIR}'" && mkdir -p "${BINDIR}"
  cd ${TOOLS_DIR}
  ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
  ## vasm
  ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
  log_info "####> VASM <####"
  wget http://sun.hasenbraten.de/vasm/release/vasm.tar.gz
  tar xzf vasm.tar.gz
  rm vasm.tar.gz
  cd vasm
  make CPU=m68k SYNTAX=mot CC=gcc
  cp vasmm68k_mot "${BINDIR}"
  cp vobjdump "${BINDIR}"
  cd ..
  ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
  ## vlink
  ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
  log_info "####> VLINK <####"
  wget http://sun.hasenbraten.de/vlink/release/vlink.tar.gz
  tar xzf vlink.tar.gz
  rm vlink.tar.gz
  cd vlink
  make
  cp vlink "${BINDIR}"
  cd "${RETURN_DIR}"
  log_ok "DONE installing vasm suite."
}

case "$1" in
  vasm)
    install_vasm
    ;;
  hatari)
	  log_warn "not implemented yet"
		;;
  *)
    install_help
    ;;
esac
