#!/bin/bash

ROOT_PASS=""

while getopts "p:" opt; do
  case ${opt} in
  p)
    ROOT_PASS=$OPTARG
    ;;
  \?)
    echo "Usage: $0 [-p root_password]"
    exit 1
    ;;
  esac
done
# Shift off the processed options so standard arguments ($1, $2, etc.) work normally
shift $((OPTIND - 1))

run_privileged() {
  if [ -z "$ROOT_PASS" ]; then
    sudo "$@"
  else
    echo "$ROOT_PASS" | sudo -S "$@"
  fi
}

echo "Update-Upgrade apt"
run_privileged add-apt-repository ppa:neovim-ppa/stable -y >/dev/null &&
  run_privileged apt update -y >/dev/null &&
  run_privileged apt upgrade -y >/dev/null &&
  run_privileged apt install curl git stow neovim fish i3 i3status i3lock dmenu git-delta -y --fix-missing >/dev/null &&
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/mkasberg/ghostty-ubuntu/HEAD/install.sh)" >/dev/null

for dir in ~/dotfiles/*/; do
  dir="${dir%*/}"
  dir="${dir##*/}"
  stow -d ~/dotfiles -t ~ "$dir"
  echo "Set up $dir config"
done

echo "------------------- Done setting up stow folders -------------------"
