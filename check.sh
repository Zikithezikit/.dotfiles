#!/bin/bash
# Quick health check for the dotfiles: syntax of every script/config, lint,
# stray absolute home paths, and a dry-run stow. Exit code is the number of
# failed checks.
cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1

# Files allowed to contain a literal /home/<user> path (vendored or one-off);
# everything else must use $HOME or ~ so the repo works on every PC.
HOME_PATH_ALLOW=(
  fish/.config/fish/functions/_tide_item_python.fish # tide: example path in a comment
  .scripts/fix-aic8800.sh
)

fail=0
check() { # label, command...
  local label=$1
  shift
  if out=$("$@" 2>&1); then printf '  ok    %s\n' "$label"; else printf '  FAIL  %s\n%s\n' "$label" "$out"; fail=$((fail + 1)); fi
}

scripts=(install.sh check.sh bash/.bashrc bin/* .scripts/*.sh polybar/.config/polybar/launch.sh polybar/.config/polybar/scripts/*.sh i3blocks/.config/i3blocks/keyboard_layout)
for f in "${scripts[@]}"; do
  check "bash -n $f" bash -n "$f"
done
# Warnings and errors only: info/style notes are mostly noise on stock files like .bashrc.
command -v shellcheck >/dev/null && check "shellcheck (warning and up)" shellcheck -S warning "${scripts[@]}"
command -v fish >/dev/null && check "fish -n (config, functions, completions, conf.d)" \
  fish -n fish/.config/fish/config.fish fish/.config/fish/functions/*.fish fish/.config/fish/completions/*.fish fish/.config/fish/conf.d/*.fish
command -v i3 >/dev/null && check "i3 -C" i3 -C -c i3/.config/i3/config
# `tmux start-server` alone never reports config errors, so source the file into
# a throwaway session instead, minus the `run` (TPM) line so no plugin code runs.
tmux_conf() {
  local rc
  tmux -L dotfiles-check -f /dev/null new-session -d || return 1
  grep -v '^run ' "$1" | tmux -L dotfiles-check source-file -
  rc=$?
  tmux -L dotfiles-check kill-server
  return $rc
}
command -v tmux >/dev/null && check "tmux config" tmux_conf tmux/.tmux.conf
command -v nvim >/dev/null && check "nvim lua syntax" nvim --headless -u NONE \
  -c 'lua for _, f in ipairs(vim.fn.glob("nvim/.config/nvim/lua/**/*.lua", true, true)) do local ok, e = loadfile(f); if not ok then error(e) end end' -c qa
# Broken symlinks tracked in the repo (a stow package with a dead link warns forever).
check "no broken tracked symlinks" bash -c '! git ls-files | while read -r f; do [ -L "$f" ] && [ ! -e "$f" ] && echo "$f"; done | grep .'
no_home_paths() {
  local out rc=0
  out=$(git grep --untracked -InE '/home/[[:alnum:]_.-]+' -- . "${HOME_PATH_ALLOW[@]/#/:(exclude)}") || rc=$?
  [ $rc -eq 1 ] && return 0 # git grep: 1 = no match, 0 = match, else error
  printf '%s\n' "$out"
  return 1
}
check "no hardcoded /home/<user> paths" no_home_paths
command -v stow >/dev/null && for d in */; do
  d=${d%/}
  [ "$d" = bin ] && continue
  check "stow -n $d" stow -n -d "$PWD" -t "$HOME" "$d"
done
echo
[ $fail -eq 0 ] && echo "all checks passed" || echo "$fail check(s) failed"
exit $fail
