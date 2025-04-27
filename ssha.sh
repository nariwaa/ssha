#!/usr/bin/env bash
set -euo pipefail

function print_help() {
  cat <<EOF

ssh-add but quicker
  ssha "key name" - will add do ssh-add ~/.ssh/"key name"
  ssha -p / ssha --pick - to pick the key if you don't know it's name or it's too long

EOF
}

function is_mounted() {
  mountpoint -q "$MOUNTPOINT"
}

# handle flags
if (( $# == 1 )); then
  case "$1" in
    --help|-h)
      print_help
      exit 0
      ;;
    --pick|-p)
      ls ~/.ssh/ | gum choose | ssh-add
      ;;
    -*)
      echo "❓ Unknown option: $1"
      print_help
      exit 1
      ;;
  esac
elif (( $# > 1 )); then
  echo "❗ Too many arguments!"
  print_help
  exit 1
fi

ssh-add ~/.ssh/$1
