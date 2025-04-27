#!/usr/bin/env bash
set -euo pipefail

function print_help() {
  cat <<EOF
ssha - A faster way to load your SSH keys

How to use it:
  ssha mykey             Loads the key ~/.ssh/mykey (or a full path like /path/to/key)
  ssha --pick or -p      Lets you pick keys from ~/.ssh/ with a simple menu
  ssha --help or -h      Shows this message
  ssha --debug or -d     Enables debug mode for troubleshooting

What it does:
  Quickly adds SSH keys to your session so you can connect securely, no fuss.
EOF
}

DEBUG_MODE=false
PICK_MODE=false
KEY_NAME=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --debug|-d)
      DEBUG_MODE=true
      shift
      ;;
    --help|-h)
      print_help
      exit 0
      ;;
    --pick|-p)
      PICK_MODE=true
      shift
      ;;
    *)
      if [[ -n "$KEY_NAME" ]]; then
        echo "❗ Too many arguments!"
        print_help
        exit 1
      fi
      KEY_NAME="$1"
      shift
      ;;
  esac
done

if $PICK_MODE; then
  if [[ -n "$KEY_NAME" ]]; then
    echo "❗ Cannot specify both --pick and a key name"
    print_help
    exit 1
  fi
  # Find keys
  keys=($(find ~/.ssh/ -maxdepth 1 -type f ! -name '*.pub' ! -name config ! -name known_hosts* ! -name authorized_keys* -printf '%f\n'))
  if $DEBUG_MODE; then
    echo "DEBUG: Found keys: ${keys[@]}"
  fi
  if [[ ${#keys[@]} -eq 0 ]]; then
    echo "No keys found in ~/.ssh/"
    exit 1
  fi
  # Let user pick keys
  selected=$(printf '%s\n' "${keys[@]}" | gum choose --cursor.foreground="" --header.foreground="" --item.foreground="" --selected.foreground="" --height 10 --cursor ">" --header "Select keys to add (use space for multiple, enter to confirm):")
  if $DEBUG_MODE; then
    echo "DEBUG: Raw selected output: '$selected'"
  fi
  # Split into array
  mapfile -t selected_array <<< "$selected"
  if $DEBUG_MODE; then
    echo "DEBUG: Selected keys array: ${selected_array[@]}"
  fi
  # Check if any keys were selected
  if [[ ${#selected_array[@]} -eq 0 ]]; then
    echo "No keys selected."
    exit 1
  fi
  # Add each selected key
  for key in "${selected_array[@]}"; do
    full_path="$HOME/.ssh/$key"
    if $DEBUG_MODE; then
      echo "DEBUG: Attempting to add key: $full_path"
    fi
    if [[ -f "$full_path" ]]; then
      echo "Adding key: $full_path"
      ssh-add "$full_path"
    else
      echo "❗ Key file not found: $full_path"
    fi
  done
elif [[ -n "$KEY_NAME" ]]; then
  if [[ "$KEY_NAME" = /* ]]; then
    key_path="$KEY_NAME"
  else
    key_path="$HOME/.ssh/$KEY_NAME"
  fi
  if $DEBUG_MODE; then
    echo "DEBUG: Attempting to add key: $key_path"
  fi
  if [[ -f "$key_path" ]]; then
    echo "Adding key: $key_path"
    ssh-add "$key_path"
  else
    echo "❗ Key file not found: $key_path"
    exit 1
  fi
else
  print_help
  exit 0
fi
