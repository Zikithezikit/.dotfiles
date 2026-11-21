#!/bin/bash

# --- Boilerplate ---

# A piped non-zero exit is a failure (not just the last command's exit).
# Matters because this script pipes a lot (e.g. curl ... | install).
set -o pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Suffix for anything moved out of the way, so one run's backups sort together.
STAMP="$(date +%Y%m%d-%H%M%S)"

# A fresh non-login shell has neither dir on PATH, and the "already installed"
# checks below (reef, cargo) need to see them.
PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

VERBOSE=""

# --- Terminal UI (colors + spinner) ---

c_reset=$'\033[0m'
c_dim=$'\033[2m'
c_green=$'\033[1;32m'
c_red=$'\033[1;31m'
c_yellow=$'\033[1;33m'
c_cyan=$'\033[1;36m'

# --- Command-line flags ---

usage() {
  cat <<EOF
Usage: $0 [-v]
  -v              Verbose: stream command output to the terminal
  -h              Show this help

Installs apt packages, ghostty, reef (bash compat for fish), and stows every
config dir in this repo into \$HOME.

Safe to re-run: steps that are already done are skipped, and real files that
are in the way of a symlink are renamed to <name>.pre-dotfiles-<timestamp>
(never deleted).
EOF
}

while getopts "vh" opt; do
  case ${opt} in
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

# Run a command as root (sudo prompts for the password itself, so it never
# lands on a command line or in `ps`).
run_privileged() { sudo "$@"; }

# --- UI helpers: spinner + step status ---

SPINNER_PID=""

# Temp workspace used by install_reef (empty when nothing is in flight).
# cleanup() wipes it so an aborted run never leaves a clone/build behind.
REEF_TMP=""

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
  { [ -n "$REEF_TMP" ] && rm -rf "$REEF_TMP"; } 2>/dev/null
  printf "\033[2K\r"
}
trap cleanup EXIT

step_message() { printf "${c_cyan}==>${c_reset} %s\n" "$1"; }
step_success() { printf "${c_green}✓${c_reset} %s\n" "$1"; }
step_error() { printf "${c_red}✗${c_reset} %s\n" "$1"; }
step_warn() { printf "${c_yellow}!${c_reset} %s\n" "$1"; }
step_skip() { printf "${c_dim}- %s (already done)${c_reset}\n" "$1"; }

have() { command -v "$1" >/dev/null 2>&1; }

# Backups of anything moved aside (see backup()), listed in the final summary.
BACKUPS=()

# Rename a path out of the way instead of overwriting it: nothing is deleted.
backup() {
  local dst="$1.pre-dotfiles-$STAMP"
  mv -n -- "$1" "$dst" && BACKUPS+=("$1 -> $dst")
}

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

# Everything below is apt-based: say so up front instead of failing on the
# first apt call somewhere else.
if ! grep -qiE '^ID(_LIKE)?=.*(debian|ubuntu)' /etc/os-release 2>/dev/null; then
  printf '%s✗%s This installer supports Debian/Ubuntu only (it uses apt).\n' "$c_red" "$c_reset"
  exit 1
fi

# Everything below runs through sudo, so make sure it actually exists before
# touching anything. When it is missing we cannot proceed: print exactly how
# to install it as root, then stop.
if ! have sudo; then
  printf '%s✗%s sudo is not installed.\n' "$c_red" "$c_reset"
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
    printf '%s✗%s Could not get sudo access.\n' "$c_red" "$c_reset"
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

# neovim is not listed: see the nvim check below.
packages=(curl git stow fish tmux i3 i3status i3lock i3lock-fancy rofi git-delta polybar picom xclip ripgrep fzf playerctl xbacklight
  brightnessctl xinput feh network-manager-gnome pulseaudio-utils pavucontrol
  x11-xserver-utils x11-xkb-utils fonts-font-awesome bat)

# Sudo is a hard requirement for everything below: verify it and stop here
# with instructions if it is not usable. Called directly (not via run_step)
# so the failure guidance is never piped to /dev/null in quiet mode.
if ! verify_sudo; then
  exit 1
fi
# Only go to apt (and the network) when something is actually missing.
missing=()
for p in "${packages[@]}"; do
  dpkg -s "$p" 2>/dev/null | grep -q '^Status: install ok installed' || missing+=("$p")
done
# Apt's neovim is a fallback only, and only when no nvim exists at all, so a
# newer hand-installed one is never shadowed or reinstalled over.
have nvim || missing+=(neovim)
if [ ${#missing[@]} -eq 0 ]; then
  step_skip "Install packages"
else
  if run_step "Update package lists" run_privileged apt update -y; then :; else FAILED="1"; fi
  if run_step "Install packages" run_privileged apt install "${missing[@]}" -y --fix-missing; then :; else FAILED="1"; fi
fi

# The LazyVim config needs nvim >= 0.11 but older Ubuntu releases ship an older
# apt build, so only warn here: the right build (AppImage/tarball) is the
# user's call.
check_nvim() {
  local v
  v=$(nvim --version 2>/dev/null | sed -n '1s/^NVIM v\([0-9]*\.[0-9]*\).*/\1/p')
  if [ -n "$v" ] && printf '0.11\n%s\n' "$v" | sort -V -C; then
    step_success "neovim $v (>= 0.11)"
  else
    step_warn "neovim ${v:-not found}: the config needs >= 0.11"
    printf '    Install a current release as /usr/local/bin/nvim (e.g. the AppImage):\n'
    printf '    https://github.com/neovim/neovim/releases/latest\n'
  fi
}
check_nvim

# Ghostty has no official Ubuntu package: run the project's installer
# directly instead of pinning a .deb, so a fresh install gets the current
# build. Skipped when present; to upgrade, run that installer by hand.
# Piped (not "$(curl)") so a failed download fails the step instead of
# running an empty script. pipefail is set above.
if have ghostty; then
  step_skip "Install ghostty"
elif run_step "Install ghostty (dynamic official installer)" bash -c \
  'curl -fsSL https://raw.githubusercontent.com/mkasberg/ghostty-ubuntu/HEAD/install.sh | bash'; then
  :
else FAILED="1"; fi

# --- Stow configs into $HOME ---

# Everything that ships a real config lives in this repo. These dirs are
# skipped: .git plumbing, bin (linked into ~/.local/bin below, so the repo can
# live anywhere) and .scripts (one-off helpers, run by hand).
skip_pkgs=(".git" ".github" "bin" ".scripts")

# Stow aborts a whole package, touching nothing, if a real file is where one of
# its links should go (e.g. a stock ~/.bashrc, or the fish_variables fish
# writes on first run). Read the conflicts from its output ($1), move those
# files aside via backup(), and return 0 if anything moved so the caller can
# retry. Symlinks into this repo are never moved.
backup_conflicts() {
  local moved=1 rel p
  while IFS= read -r rel; do
    p="$HOME/$rel"
    [ -e "$p" ] || [ -L "$p" ] || continue
    case "$(readlink -f -- "$p")" in "$DOTFILES_DIR"/*) continue ;; esac
    backup "$p" && moved=0
  done < <(printf '%s\n' "$1" | sed -nE \
    -e 's/^.*over existing target (.*) since neither a link nor a directory.*$/\1/p' \
    -e 's/^.*existing target is (neither a link nor a directory|not owned by stow): //p' | sort -u)
  return $moved
}

# Stow one package, backing up conflicts once. On failure STOW_ERR holds
# stow's output.
stow_pkg() {
  STOW_ERR=$(stow -d "$DOTFILES_DIR" -t "$HOME" "$1" 2>&1) && return 0
  backup_conflicts "$STOW_ERR" || return 1
  STOW_ERR=$(stow -d "$DOTFILES_DIR" -t "$HOME" "$1" 2>&1)
}

step_message "Stow configs into \$HOME"
STOW_FAILED=""
STOW_ERR=""
for dir in "$DOTFILES_DIR"/*/ "$DOTFILES_DIR"/.[!.]*/; do
  [ -d "$dir" ] || continue
  dir="${dir%/}"
  name="${dir##*/}"
  case " ${skip_pkgs[*]} " in
  *" $name "*) continue ;;
  esac
  printf "  ${c_dim}%-14s${c_reset}" "$name"
  if stow_pkg "$name"; then
    printf ' %s✓%s\n' "$c_green" "$c_reset"
  else
    printf ' %s✗%s\n' "$c_red" "$c_reset"
    printf '%s\n' "$STOW_ERR" | sed 's/^/      /'
    STOW_FAILED="1"
  fi
done
if [ -z "$STOW_FAILED" ]; then
  step_success "All configs stowed"
else
  step_error "Some configs failed to stow"
fi

# bin/* are plain scripts, not a stow package: link them into ~/.local/bin so
# i3 and the shell find them by a fixed path wherever the repo is cloned.
link_bin() {
  local f t
  mkdir -p "$HOME/.local/bin" || return 1
  for f in "$DOTFILES_DIR"/bin/*; do
    t="$HOME/.local/bin/${f##*/}"
    # ln -sf would silently replace a real file of the same name.
    if [ -e "$t" ] && [ ! -L "$t" ]; then backup "$t" || return 1; fi
    ln -sfn "$f" "$t" || return 1
  done
}

if run_step "Link bin/ scripts into ~/.local/bin" link_bin; then :; else FAILED="1"; fi

# --- Reef (bash compatibility layer for fish) ---

# reef is what makes fish accept bash syntax. Everything is cloned and built
# inside a throwaway mktemp dir under $TMPDIR so neither the source tree nor
# cargo's target/ lingers; only the binary (~/.local/bin/reef) and the fish
# files reef's own installer copies into ~/.config/fish are kept.
# Must run AFTER the stow step: reef writes into ~/.config/fish, and stow
# aborts the whole fish package if it finds plain files where links go.
install_reef() {
  # reef needs rustc >= 1.85 (edition 2024), newer than Ubuntu's cargo package,
  # so bootstrap rustup when cargo is missing instead of apt install cargo.
  if ! have cargo; then
    curl --proto '=https' --tlsv1.2 -fsSL https://sh.rustup.rs |
      sh -s -- -y --profile minimal --no-modify-path || return 1
    export PATH="$HOME/.cargo/bin:$PATH"
  fi

  REEF_TMP="$(mktemp -d "${TMPDIR:-/tmp}/reef-install.XXXXXX")" || return 1
  local status=0
  (
    cd "$REEF_TMP" &&
      git clone --depth 1 https://github.com/ZStud/reef reef &&
      cd reef &&
      cargo build --release &&
      install -Dm755 target/release/reef "$HOME/.local/bin/reef" &&
      PATH="$HOME/.local/bin:$PATH" fish fish/install.fish
  ) || status=$?
  # Dropped here on success/failure, and again by the EXIT trap if Ctrl-C
  # lands mid-build, so the temp clone never survives the install.
  rm -rf "$REEF_TMP"
  REEF_TMP=""
  return $status
}

if have reef; then
  step_skip "Install reef"
elif run_step "Install reef (bash compat for fish)" install_reef; then :; else FAILED="1"; fi

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

printf '\n'
if [ ${#BACKUPS[@]} -gt 0 ]; then
  step_warn "Moved existing files aside (nothing was deleted); remove them once checked:"
  printf '    %s\n' "${BACKUPS[@]}"
  printf '\n'
fi
if [ -n "$FAILED" ] || [ -n "$STOW_FAILED" ]; then
  printf '%sDone, but with errors — re-run with -v to debug.%s\n' "$c_red" "$c_reset"
  exit 1
else
  printf '%sDone! All configs set up.%s\n' "$c_green" "$c_reset"
fi

