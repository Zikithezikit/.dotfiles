#!/usr/bin/env bash
# Theme 4 style now-playing line: note, artist - title, prev/play/next.
#
# Several MPRIS players can exist at once (browser, kdeconnect phone remote,
# ...), so the player is picked explicitly: first Playing wins, otherwise the
# first Paused one, otherwise nothing is active. Metadata and click actions
# all come from that same player.
#
# Polybar runs this as a `tail = true` script (see modules.ini): the module
# shows the last line printed, so this script stays alive and streams one
# frame per line, the way polybar-spotify/zscroll and polybar-now-playing do
# (polybar has no built-in scrolling or fade). Long titles scroll inside a
# 44-char window whose edges are faded into the bar background with
# %{F#hex} tags. Motion is sub-character: the position is derived from
# elapsed time in pixels (28px/s = 4 chars/s at 7px/char) and rendered as
# character offset + a fractional %{O-n} pixel shift, refreshed ~60 times a
# second, so the text glides in <=1px steps.
#
# playerctl calls never run in the frame loop: a background refresh writes
# the current state to an atomic cache file once a second, and the loop just
# reads it (a read builtin, no fork), keeping frame gaps at the sleep time.
#
# When nothing is active a single empty line is printed, which clears the
# module (polybar 3.7.1 never updates a script module from a run that
# produces zero bytes, so an empty line is required, not silence).
#
# Usage:
#   music.sh              stream bar frames for the selected player
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

# --- display tuning ---------------------------------------------------------
WIN=44          # visible window in monospace chars (was the old hard cut)
FADE=4          # chars faded into the bar background at each edge
GAP="     "     # gap between the end of the text and the wrap-around start
HOLD_MS=3000    # show the start of a long text this long before scrolling
CHAR_PX=7       # glyph pitch of font-0 (Iosevka bold 10.5, see config.ini)
SPEED_PX=28     # scroll speed in px/s (4 chars/s)
FRAME_MS=10     # frame period; pos is time-derived, not frame-based
REFRESH_MS=1000 # how often playerctl state is refreshed (in the background)

# theme colors, read from colors.ini so they stay in sync
colors_ini="${XDG_CONFIG_HOME:-$HOME/.config}/polybar/colors.ini"
FG=$(sed -n 's/^primary[[:space:]]*=[[:space:]]*#\([0-9a-fA-F]\{6\}\).*/\1/p' "$colors_ini" | head -n1)
BG=$(sed -n 's/^background[[:space:]]*=[[:space:]]*#\([0-9a-fA-F]\{6\}\).*/\1/p' "$colors_ini" | head -n1)
FG=${FG:-ffcc66}
BG=${BG:-191d27}
FG_R=$((16#${FG:0:2})); FG_G=$((16#${FG:2:2})); FG_B=$((16#${FG:4:2}))
BG_R=$((16#${BG:0:2})); BG_G=$((16#${BG:2:2})); BG_B=$((16#${BG:4:2}))

# fade ramp: RAMP[k] blends the text color towards the bar background,
# k = 1 (dimmest) .. FADE+1 (full text color)
FADE_K=$((FADE + 1))
declare -a RAMP
for ((k = 1; k <= FADE_K; k++)); do
  RAMP[$k]=$(printf '%02x%02x%02x' \
    $(( (FG_R * k + BG_R * (FADE_K - k)) / FADE_K )) \
    $(( (FG_G * k + BG_G * (FADE_K - k)) / FADE_K )) \
    $(( (FG_B * k + BG_B * (FADE_K - k)) / FADE_K )))
done
SLEEP_ARG=$(printf '0.%03d' "$FRAME_MS")
SEP=$'\x1f'

note=$'\U000f0387'
prev=$'\uF048'
nexti=$'\uF051'
glyph_playing=$'\uF28B'
glyph_paused=$'\uF144'

# render the scrolling window of $1 starting at offset $2 with edge fade
# ($3 = both | right); result in $OUT
render_scroll() {
  local t="$1$GAP" off=$2 mode=$3
  local n=${#t} i idx ch k col out="" prev_col=""
  for ((i = 0; i < WIN; i++)); do
    idx=$(( (off + i) % n ))
    ch=${t:idx:1}
    k=0
    if [ "$mode" = both ] && [ "$i" -lt "$FADE" ]; then k=$((i + 1)); fi
    if [ "$i" -ge $((WIN - FADE)) ]; then k=$((WIN - i)); fi
    if [ "$k" -gt 0 ]; then col=${RAMP[$k]}; else col=$FG; fi
    if [ "$col" != "$prev_col" ]; then out+="%{F#$col}"; prev_col=$col; fi
    out+="$ch"
  done
  out+="%{F#$FG}"
  OUT=$out
}

emit() { # $1 = text part (markup)  $2 = status  $3 = player
  local glyph=$glyph_paused
  [ "$2" = Playing ] && glyph=$glyph_playing
  printf '%%{T6}%s%%{T-} %s %%{A1:playerctl -p '\''%s'\'' previous:}%%{T2}%s%%{T-}%%{A} %%{A1:playerctl -p '\''%s'\'' play-pause:}%%{T2}%s%%{T-}%%{A} %%{A1:playerctl -p '\''%s'\'' next:}%%{T2}%s%%{T-}%%{A}\n' \
    "$note" "$1" "$3" "$prev" "$3" "$glyph" "$3" "$nexti"
}

# background refresh: picks the player and builds "status<SEP>player<SEP>text"
# into an atomic cache file, so the frame loop never waits on playerctl
refresh() {
  local p st artist title val
  p=$(pick_player)
  st=""
  if [ -n "$p" ]; then
    st=$(playerctl -p "$p" status 2>/dev/null) || st=""
    case "$st" in Playing|Paused) ;; *) p=""; st="" ;; esac
  fi
  val=""
  if [ -n "$p" ]; then
    artist=$(playerctl -p "$p" metadata xesam:artist 2>/dev/null)
    title=$(playerctl -p "$p" metadata xesam:title 2>/dev/null)
    if [ -n "$title" ] && [ -n "$artist" ]; then
      val="$artist - $title"
    elif [ -n "$title" ]; then
      val="$title"
    fi
    val=$(printf '%s' "$val" | tr '\n' ' ')
    [ ${#val} -gt 160 ] && val="${val:0:160}"
  fi
  printf '%s%s%s%s%s\n' "$st" "$SEP" "$p" "$SEP" "$val" >"$cache.tmp"
  mv -f "$cache.tmp" "$cache"
}

cache="${TMPDIR:-/tmp}/polybar-music-cache.$$"
: >"$cache"
trap 'rm -f "$cache" "$cache.tmp"' EXIT
trap 'exit 0' INT TERM

last_refresh=0
status="" player="" text=""
disp_text="" disp_t0=0

while :; do
  if [ -n "${EPOCHREALTIME-}" ]; then
    now=$(( 10#${EPOCHREALTIME/./} / 1000 ))
  else
    now=$(( $(date +%s%N) / 1000000 ))
  fi

  if [ $((now - last_refresh)) -ge "$REFRESH_MS" ]; then
    last_refresh=$now
    refresh >/dev/null 2>&1 &
  fi

  status="" player="" text=""
  IFS=$SEP read -r status player text <"$cache"

  if [ -z "$status" ] || [ -z "$text" ]; then
    printf '\n'
    disp_text=""
    sleep 1
    continue
  fi

  if [ ${#text} -le "$WIN" ]; then
    emit "$text" "$status" "$player"
    sleep 1
    continue
  fi

  if [ "$text" != "$disp_text" ]; then
    disp_text=$text
    disp_t0=$now
  fi
  elapsed=$((now - disp_t0))
  frac=0
  if [ "$elapsed" -lt "$HOLD_MS" ]; then
    render_scroll "$text" 0 right
  else
    # pixel-exact position: whole chars select the window, the remainder is
    # applied as an offset tag so frames advance in sub-pixel steps
    period=$(( ${#text} + ${#GAP} ))
    pos_px=$(( (elapsed - HOLD_MS) * SPEED_PX / 1000 ))
    off=$(( (pos_px / CHAR_PX) % period ))
    frac=$(( pos_px % CHAR_PX ))
    render_scroll "$text" "$off" both
  fi
  if [ "$frac" -gt 0 ]; then
    part="%{O-$frac}$OUT%{O$frac}"
  else
    part=$OUT
  fi
  emit "$part" "$status" "$player"
  sleep "$SLEEP_ARG"
done
