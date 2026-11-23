#!/usr/bin/env bash
# Click action for the bar's battery module: notification with the details the
# bar has no room for (state, time left, power draw, battery health).
BAT="${BATTERY:-$(basename "$(upower -e | grep -m1 -i 'battery')" | sed 's/^battery_//')}"
[ -n "$BAT" ] || exit 0
info=$(upower -i "/org/freedesktop/UPower/devices/battery_${BAT}" 2>/dev/null) || exit 0
field() { awk -F: -v k="$1" '$1 ~ "^[ \t]*" k "$" { sub(/^[ \t]+/, "", $2); print $2; exit }' <<<"$info"; }

pct=$(field percentage)
state=$(field state)
rate=$(field energy-rate)
health=$(field capacity)
left=$(field 'time to empty')
[ -n "$left" ] || left=$(field 'time to full')

body="${state^}"
[ -n "$left" ] && case "$state" in
  discharging) body+=" - $left left" ;;
  charging) body+=" - full in $left" ;;
esac
[ -n "$rate" ] && [ "$rate" != "0 W" ] && body+=$'\n'"Power: $rate"
[ -n "$health" ] && body+=$'\n'"Health: $health"

# -r keeps a single bubble when clicked repeatedly
dunstify -r 9101 -a battery -i battery "Battery ${pct}" "$body"
