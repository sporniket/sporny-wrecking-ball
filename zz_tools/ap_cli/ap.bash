#!/usr/bin/env bash
AP_WORKDIR=$(cd $(dirname $0) && pwd)

ap_help() {
  cli_name=${0##*/}
  echo -e "
\e[90m${cli_name}\e[0m
\e[90m---===<{\e[93map\e[96m, the \e[93mA\e[96mssembly \e[93mP\e[96mrogram CLI -- version $(cat $AP_WORKDIR/VERSION)\e[90m}>===---\e[0m

\e[96mUsage:\e[0m ${cli_name} \e[93m[command]\e[0m
\e[96mCommands:\e[0m
  \e[93msetup\e[0m     CLI Setup utility
  \e[93mbuild\e[0m     CLI Build command
  \e[93mrun\e[0m       CLI program launcher
  \e[93m*\e[0m         Help
"
  exit 1
}

case "$1" in
  setup)
    "$AP_WORKDIR/commands/setup_wizz.bash" "$(pwd)"
    ;;
  build)
    "$AP_WORKDIR/commands/build.bash" "${2}"
    ;;
  run)
    "$AP_WORKDIR/commands/run.bash" "${2}"
    ;;
  *)
    ap_help
    ;;
esac
