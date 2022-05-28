#!/usr/bin/env bash
run_help() {
  cli_name=${0##*/}
  echo -e "
\e[90m${cli_name}\e[0m
Launch hatari with the given program

\e[96mUsage:\e[0m ${cli_name} \e[93m[program]\e[0m
\e[96mGoals:\e[0m
  \e[93mswb\e[0m       Autoruns the game program
  \e[93msheetext\e[0m  Autoruns the sprite sheet extractor.
  \e[93mdesktop\e[0m   Start hatari to the desktop, using the build folder as a GEMDOS drive.
  \e[93m*\e[0m         Help
"
  exit 1
}

case "$1" in
  swb|sheetext)
    AUTORUN="${AUTORUN_PREFIX}${1^^}.PRG"
    log_info "Starting ${1} as ${AUTORUN}"
    hatari --harddrive "${GEMDOS_DRIVE}" --auto "${AUTORUN}"
    ;;
  desktop)
    log_info "Starting Hatari to the desktop..."
    hatari --harddrive "${GEMDOS_DRIVE}"
    ;;
  *)
    run_help
    ;;
esac
