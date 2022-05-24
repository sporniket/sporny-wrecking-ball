#!/usr/bin/env bash
build_help() {
  cli_name=${0##*/}
  echo -e "
\e[90m${cli_name}\e[0m
Essentially, an alias to 'make'

\e[96mUsage:\e[0m ${cli_name} \e[93m[goal]\e[0m
\e[96mGoals:\e[0m
  \e[93mswb\e[0m       The game program
  \e[93msheetext\e[0m  The sprite sheet extractor.
  \e[93mall\e[0m       makes all
  \e[93m*\e[0m         Help
"
  exit 1
}

case "$1" in
  swb|sheetext|all)
    make "${1}"
    ;;
  *)
    build_help
    ;;
esac
