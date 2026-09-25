#!/usr/bin/env bash
# One polybar per connected output: "main" (with tray) on the primary
# monitor, "aux" (no tray) everywhere else.
BAR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
POLYBAR="${HOME}/.local/bin/polybar"
command -v "$POLYBAR" >/dev/null 2>&1 || POLYBAR="$(command -v polybar)"
[ -n "$POLYBAR" ] || { echo "polybar not found" >&2; exit 1; }

pkill -x polybar 2>/dev/null
pkill -x i3bar 2>/dev/null
pkill -x i3blocks 2>/dev/null
sleep 0.4

PRIMARY="$(xrandr --query | awk '/ connected/ && / primary /{print $1; exit}')"
[ -n "$PRIMARY" ] || PRIMARY="$(xrandr --query | awk '/ connected/{print $1; exit}')"

for OUTPUT in $(xrandr --query | awk '/ connected/{print $1}'); do
  if [ "$OUTPUT" = "$PRIMARY" ]; then
    BAR=main
  else
    BAR=aux
  fi
  MONITOR="$OUTPUT" "$POLYBAR" -c "$BAR_DIR/config.ini" "$BAR" \
    >"/tmp/polybar-${OUTPUT}.log" 2>&1 &
done
wait
