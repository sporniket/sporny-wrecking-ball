#!/usr/bin/env bash
echo $(pwd)
AP_WORKDIR=$(cd $(dirname $0) && pwd)

echo $AP_WORKDIR
echo $(pwd)
ap_help() {
  cli_name=${0##*/}
  echo -e "
\e[90m$cli_name\e[0m
\e[93map\e[96m, the \e[93mA\e[96mssembly \e[93mP\e[96mrogram CLI -- version $(cat $AP_WORKDIR/VERSION)\e[0m

\e[96mUsage:\e[0m $cli_name \e[93m[command]\e[0m
\e[96mCommands:\e[0m
  \e[93msetup\e[0m     Setup utility
  \e[93m*\e[0m         Help
"
  exit 1
}

case "$1" in
  setup)
    "$AP_WORKDIR/commands/setup_wizz.bash" "$2"
    ;;
  *)
    ap_help
    ;;
esac
