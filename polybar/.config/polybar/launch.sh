#!/usr/bin/env bash
# One polybar per connected output: "main" (with tray) on the primary
# monitor, "aux" (no tray) everywhere else.
BAR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
POLYBAR="/usr/bin/polybar"
command -v "$POLYBAR" >/dev/null 2>&1 || POLYBAR="$(command -v polybar)"
[ -n "$POLYBAR" ] || {
  echo "polybar not found" >&2
  exit 1
}

pkill -x polybar 2>/dev/null
pkill -x i3bar 2>/dev/null
pkill -x i3blocks 2>/dev/null
sleep 0.4

# First Battery supply, and the first Mains supply as its adapter; none on desktops.
# scope=Device is a peripheral's own battery (wireless mouse, gamepad), not the machine's.
PS_DIR="${POWER_SUPPLY_DIR:-/sys/class/power_supply}"
for S in "$PS_DIR"/*; do
  [ -r "$S/type" ] || continue
  [ "$(cat "$S/scope" 2>/dev/null)" = Device ] && continue
  [ "$(cat "$S/present" 2>/dev/null)" = 0 ] && continue # empty battery bay
  case "$(<"$S/type")" in
    Battery) [ -n "$BATTERY" ] || BATTERY="$(basename "$S")" ;;
    Mains) [ -n "$ADAPTER" ] || ADAPTER="$(basename "$S")" ;;
  esac
done
SUFFIX=""
if [ -n "$BATTERY" ]; then
  export BATTERY ADAPTER
  SUFFIX="-bat" # bar variants that include the battery module
fi

# Active outputs, primary first (it gets the tray). A connected output without a
# geometry is switched off (e.g. the laptop panel while docked) and polybar
# cannot open a bar on it. If xrandr shows none, fall back to polybar's default
# monitor so there is still a bar.
mapfile -t OUTPUTS < <(xrandr --query | awk '
  $2 == "connected" && ($3 ~ /^[0-9]+x[0-9]+[+]/ || $3 == "primary" && $4 ~ /^[0-9]+x[0-9]+[+]/) {
    if ($3 == "primary") p = $1; else o[n++] = $1 }
  END { if (p) print p; for (i = 0; i < n; i++) print o[i] }')
[ "${#OUTPUTS[@]}" -gt 0 ] || OUTPUTS=("")

LOG_DIR="${XDG_RUNTIME_DIR:-/tmp}"
BAR=main
for OUTPUT in "${OUTPUTS[@]}"; do
  MONITOR="$OUTPUT" "$POLYBAR" -c "$BAR_DIR/config.ini" "$BAR$SUFFIX" \
    >"$LOG_DIR/polybar-${OUTPUT:-default}.log" 2>&1 &
  BAR=aux
done
wait
