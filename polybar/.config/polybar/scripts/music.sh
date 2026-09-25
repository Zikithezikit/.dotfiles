#!/usr/bin/env bash
# Theme 4 style now-playing line: note, artist - title, prev/play/next.
# Prints nothing (module hides) when no active player.

status=$(playerctl status 2>/dev/null) || exit 0
case "$status" in
  Playing|Paused) ;;
  *) exit 0 ;;
esac

artist=$(playerctl metadata xesam:artist 2>/dev/null)
title=$(playerctl metadata xesam:title 2>/dev/null)

if [ -n "$title" ] && [ -n "$artist" ]; then
  text="$artist - $title"
elif [ -n "$title" ]; then
  text="$title"
else
  exit 0
fi
text=$(printf '%s' "$text" | tr '\n' ' ' | cut -c 1-44)

if [ "$status" = "Playing" ]; then
  state=$'\uF28B'
else
  state=$'\uF144'
fi

note=$'\uF001'
prev=$'\uF048'
nexti=$'\uF051'

printf '%%{T6}%s%%{T-} %s %%{A1:playerctl previous:}%%{T2}%s%%{T-}%%{A} %%{A1:playerctl play-pause:}%%{T2}%s%%{T-}%%{A} %%{A1:playerctl next:}%%{T2}%s%%{T-}%%{A}\n' \
  "$note" "$text" "$prev" "$state" "$nexti"
