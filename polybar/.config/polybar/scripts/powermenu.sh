#!/usr/bin/env bash
# Power menu behind the bar's power icon.
choice=$(printf '%s\n' "Lock" "Logout" "Reboot" "Shutdown" "Cancel" |
  rofi -dmenu -i -p "Power" -width 12 -lines 5)
case "$choice" in
  Lock)     i3lock-fancy ;;
  Logout)   i3-msg exit ;;
  Reboot)   systemctl reboot ;;
  Shutdown) systemctl poweroff ;;
esac
