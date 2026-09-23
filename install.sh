#!/bin/bash

# --- Boilerplate ---

# A piped non-zero exit is a failure (not just the last command's exit).
# Matters because this script pipes a lot (e.g. curl ... | install).
set -o pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ROOT_PASS=""
VERBOSE=""

# --- Terminal UI (colors + spinner) ---

c_reset=$'\033[0m'
c_dim=$'\033[2m'
c_green=$'\033[1;32m'
c_red=$'\033[1;31m'
c_cyan=$'\033[1;36m'

# --- Command-line flags ---

usage() {
  cat <<EOF
Usage: $0 [-p root_password] [-v]
  -p <password>   Root password for sudo (otherwise prompted interactively)
  -v              Verbose: stream command output to the terminal
  -h              Show this help

Installs apt packages, ghostty, and stows every config dir in this repo
into \$HOME.
EOF
}

while getopts "p:vh" opt; do
  case ${opt} in
  p) ROOT_PASS=$OPTARG ;;
  v) VERBOSE=1 ;;
  h)
    usage
    exit 0
    ;;
  \?)
    usage
    exit 1
    ;;
  esac
done
shift $((OPTIND - 1))

# Run a command as root: prompt for the password when none was supplied.
run_privileged() {
  if [ -z "$ROOT_PASS" ]; then
    sudo "$@"
  else
    # -S is needed to read the password from stdin for non-interactive runs
    # (e.g. `-p` from CI or another script).
    echo "$ROOT_PASS" | sudo -S "$@"
  fi
}

# --- UI helpers: spinner + step status ---

SPINNER_PID=""

# Flying in a background process while a step runs. Braille frames are
# picked because they look smooth at slow refreshes.
spin() {
  local chars='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
  while :; do
    for ((i = 0; i < ${#chars}; i++)); do
      # \r redraws in place; [2K (in stop_spinner) erases the line so no
      # leftover frame remains after completion.
      printf "\r${c_cyan}%s${c_reset} ${c_dim}%s${c_reset}" "${chars:i:1}" "$1"
      sleep 0.08
    done
  done
}

# +m: job control off so the background spinner's PID is not printed.
start_spinner() {
  set +m
  { spin "$1" & } 2>/dev/null
  SPINNER_PID=$!
}

stop_spinner() {
  { kill "$SPINNER_PID" && wait; } 2>/dev/null
  SPINNER_PID=""
  set -m
  printf "\033[2K\r" # wipe the spinner line entirely
}

# Kill the spinner even if the script aborts (Ctrl-C, a step crashing), so a
# stray animation is never left behind on the terminal.
cleanup() {
  { kill "$SPINNER_PID"; } 2>/dev/null
  printf "\033[2K\r"
}
trap cleanup EXIT

step_message() { printf "${c_cyan}==>${c_reset} %s\n" "$1"; }
step_success()  { printf "${c_green}✓${c_reset} %s\n" "$1"; }
step_error()    { printf "${c_red}✗${c_reset} %s\n" "$1"; }

# Run one labeled step: show the spinner while it executes, then a ✓/✗.
# Returns a non-zero exit code so the caller can remember the failure.
run_step() {
  local label=$1
  shift
  step_message "$label"
  start_spinner "$label"
  if [ -n "$VERBOSE" ]; then
    "$@"
  else
    "$@" >/dev/null 2>&1
  fi
  local status=$?
  stop_spinner
  if [ $status -eq 0 ]; then
    step_success "$label"
  else
    step_error "$label"
  fi
  return $status
}

# --- Preflight ---

# Everything below runs through sudo, so make sure it actually exists before
# touching anything. When it is missing we cannot proceed: print exactly how
# to install it as root, then stop.
if ! command -v sudo >/dev/null 2>&1; then
  printf "${c_red}✗${c_reset} sudo is not installed.\n"
  cat <<EOF

Without sudo this script cannot install anything. As the root user, run:

  apt update && apt install -y sudo

Then give your user sudo rights and come back:

  usermod -aG sudo "$USER"
  su - "$USER"

Re-run this script afterwards.
EOF
  exit 1
fi

# Verify sudo actually works (wrong password / user not in sudoers), priming
# the credentials so later steps don't each prompt. Kept outside run_step so
# the guidance below is never piped to /dev/null in quiet mode.
verify_sudo() {
  if ! run_privileged true; then
    printf "${c_red}✗${c_reset} Could not get sudo access.\n"
    cat <<EOF

Check that "$(id -un)" is in the sudo group:

  groups "$(id -un)"            # must list sudo
  su - -c "usermod -aG sudo $(id -un)"

Then log out and back in, and re-run this script.
EOF
    return 1
  fi
  step_success "sudo is ready"
}

# --- The install steps ---

# Remember every step that failed. We keep going even after a failure so the
# user sees a full report instead of stopping at the first error.
FAILED=""

# add-apt-repository cannot be trusted to skip an already-configured PPA
# (and its exit code is historically unreliable), so we detect it ourselves.
ppa_configured() { apt-cache policy 2>/dev/null | grep -qi "neovim-ppa"; }
install_ppa() {
  if ! ppa_configured; then
    run_privileged add-apt-repository ppa:neovim-ppa/stable -y
  fi
}

packages=(curl git stow neovim fish tmux i3 i3status i3lock dmenu git-delta)

# Sudo is a hard requirement for everything below: verify it and stop here
# with instructions if it is not usable. Called directly (not via run_step)
# so the failure guidance is never piped to /dev/null in quiet mode.
if ! verify_sudo; then
  exit 1
fi
if run_step "Add neovim stable PPA (skip if present)" install_ppa; then :; else FAILED="1"; fi
if run_step "Update package lists" run_privileged apt update -y; then :; else FAILED="1"; fi
if run_step "Upgrade existing packages" run_privileged apt upgrade -y; then :; else FAILED="1"; fi
if run_step "Install packages" run_privileged apt install "${packages[@]}" -y --fix-missing; then :; else FAILED="1"; fi

# Ghostty has no official Ubuntu package: run the project's installer
# directly instead of pinning a .deb, so we always get the current build.
if run_step "Install ghostty (dynamic official installer)" bash -c \
  "$(curl -fsSL https://raw.githubusercontent.com/mkasberg/ghostty-ubuntu/HEAD/install.sh)"; then
  :; else FAILED="1"; fi

# --- Stow configs into $HOME ---

# Everything that ships a real config lives in this repo. These dirs are
# skipped: .git plumbing, and bin/.scripts (loose helper scripts we link
# manually, not through stow).
skip_pkgs=(".git" ".github" "bin" ".scripts")

step_message "Stow configs into \$HOME"
STOW_FAILED=""
for dir in "$DOTFILES_DIR"/*/ "$DOTFILES_DIR"/.[!.]*/; do
  [ -d "$dir" ] || continue
  dir="${dir%/}"
  name="${dir##*/}"
  case " ${skip_pkgs[*]} " in
  *" $name "*) continue ;;
  esac
  printf "  ${c_dim}%-14s${c_reset}" "$name"
  if stow -d "$DOTFILES_DIR" -t "$HOME" "$name"; then
    printf " ${c_green}✓${c_reset}\n"
  else
    printf " ${c_red}✗${c_reset}\n"
    STOW_FAILED="1"
  fi
done
if [ -z "$STOW_FAILED" ]; then
  step_success "All configs stowed"
else
  step_error "Some configs failed to stow"
fi

# --- Tmux plugins (TPM) ---

# TPM and its plugins live outside the repo (cloned into ~/.tmux/plugins), so
# stow only provides ~/.tmux.conf. Bootstrap TPM here, then let it install the
# plugins declared in the config. Needs the stow step above to have run first.
install_tmux_plugins() {
  local tpm_dir="$HOME/.tmux/plugins/tpm"
  if [ ! -d "$tpm_dir" ]; then
    git clone --depth 1 https://github.com/tmux-plugins/tpm "$tpm_dir" || return 1
  fi
  "$tpm_dir/bin/install_plugins"
}

if [ -f "$HOME/.tmux.conf" ]; then
  if run_step "Install tmux plugins (TPM)" install_tmux_plugins; then :; else FAILED="1"; fi
fi

# --- Summary ---

printf "\n"
if [ -n "$FAILED" ] || [ -n "$STOW_FAILED" ]; then
  printf "${c_red}Done, but with errors — re-run with -v to debug.${c_reset}\n"
  exit 1
else
  printf "${c_green}Done! All configs set up.${c_reset}\n"
fi