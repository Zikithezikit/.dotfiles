#!/usr/bin/env bash
# Theme 4 style now-playing line: note, artist - title, prev/play/next.
#
# Several MPRIS players can exist at once (browser, kdeconnect phone remote,
# ...), so the player is picked explicitly: first Playing wins, otherwise the
# first Paused one, otherwise nothing is active. Metadata and click actions
# all come from that same player.
#
# Polybar 3.7.1 only updates a non-tail script module when the script prints
# a line (it reads stdout with POLLIN; a run that outputs zero bytes ends at
# EOF without ever updating, keeping the previous text). So display mode
# ALWAYS prints exactly one line: the now-playing markup, or an empty line
# that clears the module.
#
# Usage:
#   music.sh              print the bar line for the selected player
#   music.sh <command>    run a playerctl command (play-pause, next, ...) on
#                         that same selected player (used by the i3 keys)

pick_player() {
  local p st paused=""
  while IFS= read -r p; do
    [ -n "$p" ] || continue
    st=$(playerctl -p "$p" status 2>/dev/null) || continue
    case "$st" in
      Playing) printf '%s\n' "$p"; return 0 ;;
      Paused) [ -n "$paused" ] || paused=$p ;;
    esac
  done < <(playerctl -l 2>/dev/null)
  [ -n "$paused" ] && printf '%s\n' "$paused"
  return 0
}

if [ -n "$1" ]; then
  player=$(pick_player)
  [ -n "$player" ] || player=$(playerctl -l 2>/dev/null | head -n 1)
  [ -n "$player" ] || exit 0
  exec playerctl -p "$player" "$@"
fi

line=""
player=$(pick_player)
if [ -n "$player" ]; then
  status=$(playerctl -p "$player" status 2>/dev/null)
  case "$status" in
    Playing|Paused)
      artist=$(playerctl -p "$player" metadata xesam:artist 2>/dev/null)
      title=$(playerctl -p "$player" metadata xesam:title 2>/dev/null)
      if [ -n "$title" ] && [ -n "$artist" ]; then
        text="$artist - $title"
      elif [ -n "$title" ]; then
        text="$title"
      else
        text=""
      fi
      if [ -n "$text" ]; then
        text=$(printf '%s' "$text" | tr '\n' ' ' | cut -c 1-44)

        if [ "$status" = "Playing" ]; then
          state=$'\uF28B'
        else
          state=$'\uF144'
        fi

        note=$'\U000f0387'
        prev=$'\uF048'
        nexti=$'\uF051'

        cmd_prev="playerctl -p '$player' previous"
        cmd_toggle="playerctl -p '$player' play-pause"
        cmd_next="playerctl -p '$player' next"

        line=$(printf '%%{T6}%s%%{T-} %s %%{A1:%s:}%%{T2}%s%%{T-}%%{A} %%{A1:%s:}%%{T2}%s%%{T-}%%{A} %%{A1:%s:}%%{T2}%s%%{T-}%%{A}' \
          "$note" "$text" "$cmd_prev" "$prev" "$cmd_toggle" "$state" "$cmd_next" "$nexti")
      fi
      ;;
  esac
fi

printf '%s\n' "$line"
