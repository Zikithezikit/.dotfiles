#!/bin/bash

# Installs everything needed to run i3 inside WSL, via a TurboVNC X server.
#
# Run it from a normal shell -- it needs sudo, and it will prompt:
#
#   bash ~/.dotfiles/wsl/install-wsl.sh
#
# Safe to re-run; every step checks whether it is already done. See README.md
# in this directory for what to do on the Windows side afterwards.

set -o pipefail

WSL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$WSL_DIR/.." && pwd)"

TURBOVNC_VERSION="${TURBOVNC_VERSION:-3.3.1}"
NERD_FONTS_VERSION="${NERD_FONTS_VERSION:-3.5.1}"

ROOT_PASS=""
VERBOSE=""

# --- Terminal UI (matches install.sh) ---

c_reset=$'\033[0m'
c_dim=$'\033[2m'
c_green=$'\033[1;32m'
c_red=$'\033[1;31m'
c_cyan=$'\033[1;36m'

usage() {
  cat <<EOF
Usage: $0 [-p root_password] [-v]
  -p <password>   Root password for sudo (otherwise prompted interactively)
  -v              Verbose: stream command output to the terminal
  -h              Show this help
EOF
}

while getopts "p:vh" opt; do
  case ${opt} in
  p) ROOT_PASS="$OPTARG" ;;
  v) VERBOSE=1 ;;
  h) usage; exit 0 ;;
  \?) usage; exit 1 ;;
  esac
done
shift $((OPTIND - 1))

run_privileged() {
  if [ -z "$ROOT_PASS" ]; then
    sudo "$@"
  else
    # -S is needed to read the password from stdin for non-interactive runs.
    echo "$ROOT_PASS" | sudo -S "$@"
  fi
}

SPINNER_PID=""
TMPDIR_WORK=""

spin() {
  local chars='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
  while :; do
    for ((i = 0; i < ${#chars}; i++)); do
      printf "\r${c_cyan}%s${c_reset} ${c_dim}%s${c_reset}" "${chars:i:1}" "$1"
      sleep 0.08
    done
  done
}

start_spinner() {
  set +m
  { spin "$1" & } 2>/dev/null
  SPINNER_PID=$!
}

stop_spinner() {
  { kill "$SPINNER_PID" && wait; } 2>/dev/null
  SPINNER_PID=""
  set -m
  printf "\033[2K\r"
}

cleanup() {
  { kill "$SPINNER_PID"; } 2>/dev/null
  { [ -n "$TMPDIR_WORK" ] && rm -rf "$TMPDIR_WORK"; } 2>/dev/null
  printf "\033[2K\r"
}
trap cleanup EXIT

step_message()  { printf "${c_cyan}==>${c_reset} %s\n" "$*"; }
step_success() { printf "${c_green}✓${c_reset} %s\n" "$*"; }
step_error()   { printf "${c_red}✗${c_reset} %s\n" "$*"; }

run_step() {
  local label="$1"; shift
  step_message "$label"
  start_spinner "$label"
  if [ -n "$VERBOSE" ]; then "$@"; else "$@" >/dev/null 2>&1; fi
  local status=$?
  stop_spinner
  if [ $status -eq 0 ]; then step_success "$label"; else step_error "$label"; fi
  return $status
}

# --- Preflight ---

if ! command -v sudo >/dev/null 2>&1; then
  printf "${c_red}✗${c_reset} sudo is not installed.\n"
  exit 1
fi

if ! run_privileged true; then
  printf "${c_red}✗${c_reset} Could not get sudo access.\n"
  cat <<EOF

Check that "$(id -un)" is in the sudo group:

  groups "$(id -un)"            # must list sudo
  su - -c "usermod -aG sudo $(id -un)"

Then log out and back in, and re-run this script.
EOF
  exit 1
fi
step_success "sudo is ready"

FAILED=""

# ---------------------------------------------------------------------------
# 1. APT packages
# ---------------------------------------------------------------------------
# Everything i3/.config/i3/config and polybar/.config/polybar/modules.ini
# shell out to, but which the repo's own install.sh does not (yet) pull in --
# so on a fresh machine i3 comes up with a dead bar and dead keybindings.
#
# Deliberately NOT installed: network-manager-applet and kdeconnect. Both are
# started unconditionally by the i3 config, and both are meaningless under
# WSL (no NetworkManager, no Bluetooth); the config now checks for them
# first.
packages=(
  picom                # compositing: i3 itself draws no transparency
  feh                  # wallpaper
  i3lock-fancy         # bound to $mod+Ctrl+l
  xbacklight           # bound to the brightness keys
  pavucontrol          # polybar's volume module right-click
  pulseaudio-utils    # pactl, for the volume keys and polybar's pulse module
  alsa-utils
  xclip                # clipboard over X11
  fonts-font-awesome   # the icons in the i3 workspace names
  fonts-dejavu-core
  dbus-x11             # dbus-launch, for a private session bus
)

install_packages() {
  run_privileged apt update -y
  run_privileged apt install -y --no-install-recommends "${packages[@]}"
}
if run_step "Install X session packages" install_packages; then :; else FAILED=1; fi

# ---------------------------------------------------------------------------
# 2. TurboVNC
# ---------------------------------------------------------------------------
# Not in Ubuntu's repos, so it comes straight from upstream as a .deb.
# apt install ./file.deb rather than dpkg -i, so its own dependencies (libjpeg,
# libgnutls, ...) are pulled in.
install_turbovnc() {
  local url="https://github.com/TurboVNC/turbovnc/releases/download/${TURBOVNC_VERSION}/turbovnc_${TURBOVNC_VERSION}_amd64.deb"
  TMPDIR_WORK="$(mktemp -d "${TMPDIR:-/tmp}/turbovnc.XXXXXX")" || return 1
  curl -fsSL -o "$TMPDIR_WORK/turbovnc.deb" "$url" || return 1
  run_privileged apt install -y "$TMPDIR_WORK/turbovnc.deb"
  local status=$?
  rm -rf "$TMPDIR_WORK"; TMPDIR_WORK=""
  return $status
}
if [ -x /opt/TurboVNC/bin/vncserver ]; then
  step_success "TurboVNC already installed"
else
  if run_step "Install TurboVNC $TURBOVNC_VERSION" install_turbovnc; then :; else FAILED=1; fi
fi

# ---------------------------------------------------------------------------
# 3. Nerd Fonts
# ---------------------------------------------------------------------------
# polybar's bar renders every module icon through these; without them the bar
# is a row of tofu boxes. Installed into ~/.local/share/fonts so no sudo is
# needed and they survive an apt reinstall.
#
# Only Regular/Italic/Bold/BoldItalic are kept: the remaining seven weights are
# ~13 MB each of glyph data this setup never selects.
install_fonts() {
  local base="https://github.com/ryanoasis/nerd-fonts/releases/download/v${NERD_FONTS_VERSION}"
  local dest="$HOME/.local/share/fonts/NerdFonts"
  TMPDIR_WORK="$(mktemp -d "${TMPDIR:-/tmp}/nerdfonts.XXXXXX")" || return 1
  mkdir -p "$dest" || return 1

  curl -fsSL -o "$TMPDIR_WORK/iosevka.tar.xz" "$base/Iosevka.tar.xz" || return 1
  curl -fsSL -o "$TMPDIR_WORK/symbols.tar.xz" "$base/NerdFontsSymbolsOnly.tar.xz" || return 1
  tar -xf "$TMPDIR_WORK/iosevka.tar.xz" -C "$TMPDIR_WORK" || return 1
  tar -xf "$TMPDIR_WORK/symbols.tar.xz" -C "$TMPDIR_WORK" || return 1

  local w
  for w in Regular Italic Bold BoldItalic; do
    cp "$TMPDIR_WORK/IosevkaNerdFont-$w.ttf"     "$dest/" 2>/dev/null
    cp "$TMPDIR_WORK/IosevkaNerdFontMono-$w.ttf" "$dest/" 2>/dev/null
  done
  cp "$TMPDIR_WORK/SymbolsNerdFont-Regular.ttf"     "$dest/" 2>/dev/null
  cp "$TMPDIR_WORK/SymbolsNerdFontMono-Regular.ttf" "$dest/" 2>/dev/null

  fc-cache -f "$dest" >/dev/null 2>&1
  rm -rf "$TMPDIR_WORK"; TMPDIR_WORK=""
}
if [ -d "$HOME/.local/share/fonts/NerdFonts" ] \
   && fc-match "Symbols Nerd Font" 2>/dev/null | grep -q "Symbols Nerd Font"; then
  step_success "Nerd Fonts already installed"
else
  if run_step "Install Nerd Fonts (Iosevka + Symbols)" install_fonts; then :; else FAILED=1; fi
fi

# ---------------------------------------------------------------------------
# 4. Stow the wsl package
# ---------------------------------------------------------------------------
stow_wsl() {
  [ -d "$DOTFILES_DIR/wsl" ] || return 1
  stow -d "$DOTFILES_DIR" -t "$HOME" wsl
}
if run_step "Stow the wsl package" stow_wsl; then :; else FAILED=1; fi

# ---------------------------------------------------------------------------
# 5. Stop the viewer resizing the desktop out from under i3
# ---------------------------------------------------------------------------
# TurboVNC lets the client resize the X screen to match itself. That sounds
# helpful and is not, here: the screen grows to the client's size while the
# output keeps the position it was given, so i3 ends up placing windows off
# the right edge of the screen -- "a window that does not fit in i3", and a
# desktop that looks broken in a way that is very hard to diagnose from
# inside. Disabling remote resize pins the desktop to GEOMETRY in
# ~/.config/i3-wsl/config, which is what you set on purpose.
#
# The directive ships commented out, so this is a one-line uncomment. Done
# with sed rather than a rewrite so the rest of the documented file, with all
# its examples, is left alone.
SECCONF=/etc/turbovncserver-security.conf
lock_desktop_size() {
  [ -f "$SECCONF" ] || return 1
  grep -qE '^\s*#?\s*no-remote-resize' "$SECCONF" || return 1
  if grep -qE '^\s*no-remote-resize' "$SECCONF"; then
    return 0                       # already enabled
  fi
  sed -i 's/^\([[:space:]]*\)#\(no-remote-resize\)/\1\2/' "$SECCONF"
}
if run_step "Pin the VNC desktop size (disable remote resize)" lock_desktop_size; then
  :
else
  step_message "Could not edit $SECCONF -- the viewer may still resize the desktop"
fi

# ---------------------------------------------------------------------------
# 6. Stage the Windows viewer
# ---------------------------------------------------------------------------
# The viewer has to be installed on the Windows side -- there is no way to
# usefully run a WSL-side X server without it -- so fetch it here and drop it
# in the Windows Downloads folder, ready to double-click. Doing it from WSL
# also sidesteps pasting URLs into cmd.exe, where quoting and backslashes are
# a reliable source of trouble.
#
# It is only staged, never run: TurboVNC's package is an Inno Setup installer
# that also carries the Windows *server*, and whether to install that is the
# user's call, not ours.
stage_windows_viewer() {
  # Only meaningful under WSL with the Windows drive mounted.
  [ -d /mnt/c/Users ] || return 1

  local exe="TurboVNC-${TURBOVNC_VERSION}-x64.exe"
  local url="https://github.com/TurboVNC/turbovnc/releases/download/${TURBOVNC_VERSION}/${exe}"
  local cached="${XDG_CACHE_HOME:-$HOME/.cache}/i3-wsl/$exe"

  if [ ! -s "$cached" ]; then
    mkdir -p "$(dirname "$cached")" || return 1
    curl -fsSL -o "$cached.part" "$url" || return 1
    mv "$cached.part" "$cached" || return 1
  fi

  # Ask Windows which profile is the real user. $USER in WSL is a different
  # name and is no use here.
  local winuser dest
  winuser="$(cmd.exe /c 'echo %USERNAME%' 2>/dev/null | tr -d '\r' | tail -1)"
  [ -n "$winuser" ] || return 1
  if [ -d "/mnt/c/Users/$winuser/Downloads" ]; then
    dest="/mnt/c/Users/$winuser/Downloads"
  else
    dest="/mnt/c/Users/$winuser"
  fi
  [ -d "$dest" ] || return 1

  cp -f "$cached" "$dest/$exe" || return 1
  echo "$dest/$exe"
}

VIEWER_PATH="$(stage_windows_viewer 2>/dev/null)"
if [ -n "$VIEWER_PATH" ]; then
  step_success "Staged the Windows viewer in ${VIEWER_PATH#/mnt/c/}"
else
  step_message "Could not stage the Windows viewer; download it from"
  printf "  %shttps://github.com/TurboVNC/turbovnc/releases/download/%s/TurboVNC-%s-x64.exe%s\n" \
    "$c_dim" "$TURBOVNC_VERSION" "$TURBOVNC_VERSION" "$c_reset"
fi

# ---------------------------------------------------------------------------
# 7. Put the launcher on the Windows Desktop
# ---------------------------------------------------------------------------
# One double-click that starts the session and opens the viewer fullscreen.
# Lives in the repo at wsl/windows/, and is copied rather than stowed because a
# symlink from the Linux home into C:\ is not something Windows follows.
deploy_launcher() {
  local src="$WSL_DIR/windows/i3-wsl.bat"
  [ -f "$src" ] || return 1
  [ -d /mnt/c/Users ] || return 1

  local winuser dest
  winuser="$(cmd.exe /c 'echo %USERNAME%' 2>/dev/null | tr -d '\r' | tail -1)"
  [ -n "$winuser" ] || return 1
  dest="/mnt/c/Users/$winuser/Desktop"
  [ -d "$dest" ] || return 1

  cp -f "$src" "$dest/i3-wsl.bat" || return 1
  echo "$dest/i3-wsl.bat"
}

LAUNCHER_PATH="$(deploy_launcher 2>/dev/null)"
if [ -n "$LAUNCHER_PATH" ]; then
  step_success "Launcher on your Desktop: ${LAUNCHER_PATH#/mnt/c/}"
else
  step_message "Could not copy the launcher to the Desktop; it is at wsl/windows/i3-wsl.bat"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

printf "\n"
if [ -n "$FAILED" ]; then
  printf "${c_red}Some steps failed -- re-run with -v to see why.${c_reset}\n\n"
  exit 1
fi

if [ -n "$VIEWER_PATH" ]; then
cat <<EOF
${c_green}Done!${c_reset}

Two steps left, one on each side.

${c_cy}1. Windows${c_reset}   double-click

      ${LAUNCHER_PATH:-(not deployed)}

    That starts the session and opens the viewer already connected and in
    fullscreen. First time only, install the viewer -- it is at:

      ${VIEWER_PATH:-(not staged; see the URL above)}

    The wizard offers the TurboVNC Server as well as the Viewer -- you only
    need the ${c_dim}Viewer${c_reset}, because the X server runs inside WSL.
    Deselect the server and no elevation prompt appears.

    To skip the wizard, run the installer with these flags instead:

      /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /CURRENTUSER

    ${c_dim}/CURRENTUSER${c_reset} makes it a per-user install, no elevation. Note
    this is an ${c_dim}Inno Setup${c_reset} package, so the NSIS-style /S and /D= flags
    do nothing on it -- that is the usual reason "silent install" attempts
    here fail.

${c_cy}2. WSL${c_reset}        start the session

     i3-wsl-up

   That is the one command to remember: it re-checks everything, installs
   anything still missing, and starts the session. Then in the viewer connect
   to  ${c_dim}localhost:5912${c_reset}
   and press  ${c_dim}F11${c_reset} for fullscreen. In a windowed viewer Windows
   eats the Super key, so every i3 binding (\$mod+Return, \$mod+d, ...) is dead.

Sanity check at any time:  i3-wsl status  /  i3-wsl doctor  /  i3-wsl logs

${c_dim}WSLg is left enabled on purpose, so you can still open single GUI apps
as native Windows windows. They just will not be tiled by i3 -- use the VNC
session for anything that should live in i3.${c_reset}
EOF
else
cat <<EOF
${c_green}Done!${c_reset}

Install the TurboVNC Viewer on the Windows side -- the x64 installer from
https://github.com/TurboVNC/turbovnc/releases -- then:

  i3-wsl start

and connect to  ${c_dim}localhost:5912${c_reset}, pressing F11 for fullscreen.

${c_dim}WSLg is left enabled on purpose, so you can still open single GUI apps
as native Windows windows. They just will not be tiled by i3.${c_reset}
EOF
fi
