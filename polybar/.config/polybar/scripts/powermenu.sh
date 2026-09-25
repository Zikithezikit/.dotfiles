#!/usr/bin/env bash
# Power menu behind the bar's power icon.
#
# -i is case-insensitive matching; dmenu mode reads the menu on stdin and
# prints the choice on stdout. Width/rows/placeholder come from -theme-str
# because the -width/-lines flags this used to pass are deprecated and are
# silently ignored on rofi 1.7.x. The narrow width and hidden mode-switcher
# suit a 5-item list.
choice=$(printf '%s\n' "Lock" "Logout" "Reboot" "Shutdown" "Cancel" |
  rofi -dmenu -i -p "Power" \
    -theme-str "window { width: 22%; }" \
    -theme-str "listview { lines: 5; }" \
    -theme-str "mode-switcher { enabled: false; }" \
    -theme-str "entry { placeholder: false; }")
case "$choice" in
  Lock)     i3lock-fancy ;;
  Logout)   i3-msg exit ;;
  Reboot)   systemctl reboot ;;
  Shutdown) systemctl poweroff ;;
esac
