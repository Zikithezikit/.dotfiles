# Haimov's .dotfiles

Config for an Ubuntu + i3 desktop or laptop, managed with [GNU Stow](https://www.gnu.org/software/stow/).
Each top-level folder is a stow package that mirrors `$HOME` (e.g. `i3/.config/i3/config` -> `~/.config/i3/config`).

## Install

```bash
git clone https://github.com/Zikithezikit/.dotfiles ~/.dotfiles
cd ~/.dotfiles && bash ./install.sh      # add -v to see command output
```

Needs `sudo` and a Debian/Ubuntu-like system (it stops with a message otherwise). It runs, in order:

1. apt packages (fish, tmux, i3, polybar, rofi, picom, stow, ripgrep, fzf, bat, brightnessctl, xinput, ...)
2. ghostty
3. stow for every package into `$HOME`
4. links `bin/*` into `~/.local/bin`
5. [reef](https://github.com/ZStud/reef) (bash syntax support for fish)
6. tmux plugins through TPM

It is safe to re-run: finished steps are skipped, and a failed step doesn't stop the rest (the summary lists what to retry).
If a real file is in the way of a symlink (a stock `~/.bashrc`, for example) it is renamed to `<name>.pre-dotfiles-<timestamp>`, never deleted, and listed at the end.

Neovim is not installed from apt (Ubuntu's is too old). The config needs 0.11 or newer; the script warns if yours is older and points to the release page.

After installing, log out and pick the i3 session, and run `chsh -s "$(command -v fish)"` to make fish the login shell.

## What's inside

| Package | What it configures |
| --- | --- |
| `i3`, `polybar`, `rofi`, `gammastep`, `i3blocks` | window manager, bar, launcher, night light (i3blocks is an unused fallback bar) |
| `fish`, `bash` | shells; fish uses tide for the prompt and reef for bash compatibility |
| `nvim` | LazyVim-based Neovim setup |
| `tmux` | prefix `C-s`, vim-style navigation, sessions saved and restored across reboots |
| `ghostty` | terminal |
| `git`, `gh`, `lazygit` | git defaults and aliases, delta pager, SSH commit signing, GitHub CLI |
| `clangd`, `sqlfluff` | language tooling defaults |
| `bin/` | helper scripts (not stowed, see below) |

### Helper scripts (`bin/`)

`install.sh` links these into `~/.local/bin`, and i3 calls them from there.

| Script | Does |
| --- | --- |
| `monitor` | lines up all connected outputs left to right, primary first; does nothing with one screen (`$mod+Shift+s`, and at i3 start) |
| `resolution` | toggles the primary output between 1920x1080 and 1680x1050 (`$mod+Shift+n`) |
| `brightness up\|down` | brightness keys: `brightnessctl`, falling back to `xbacklight`; silent no-op on desktops |
| `touchpad` | tap-to-click and natural scrolling, only on devices that are real touchpads |

## Desktop vs laptop

The same checkout adapts to whichever machine it is on:

- **Battery indicator:** `polybar/launch.sh` looks in `/sys/class/power_supply` for a laptop battery and its adapter (BAT0/BAT1, AC/ADP1, ...). The module is added to the bar only when one exists; wireless mouse or gamepad batteries are ignored. The percentage turns red at 15%.
- **Monitors:** bars open only on active outputs. Override the display helpers with `MONITOR_PRIMARY` (default `DP-1`) and `MONITOR_MODE` (default `1920x1080`).
- **Paths:** nothing refers to a username or to where the repo is cloned. Directories are added to `PATH` (bash and fish) only if they exist.
- **Obsidian vault:** `~/Documents/vault`, or set `OBSIDIAN_VAULT`.
- **`audio_server`** (fish) binds to whatever IP the machine currently uses to reach the network.

## Shell, tmux and git details

- **fish:** `EDITOR` and `VISUAL` default to nvim. fzf bindings are on (`Ctrl-R` history, `Ctrl-T` files, `Alt-C` directories). Git abbreviations: `g ga gc gd gds gl gp gst gsw`, plus `lg` for lazygit. `frg` is a live ripgrep + fzf search that opens the match in your editor.
- **tmux:** true color, OSC52 clipboard, 20k lines of history, 10 ms escape time. `<prefix> r` reloads the config.
- **git:** fast-forward-only pulls, prune on fetch, rerere, auto-stash on rebase, branches sorted by recent commit. GitHub credentials come from `gh`.

## Checking your changes

```bash
./check.sh
```

Runs `bash -n` and (when installed) shellcheck on every script, `fish -n` on the fish config, `i3 -C`, a tmux config load, a Lua syntax pass over the nvim config, checks for broken tracked symlinks and for hardcoded `/home/<user>` paths, and a `stow -n` dry run for every package. The exit code is the number of failed checks.

## Adding or changing config

- New tool: make `<tool>/<path relative to $HOME>` and run `stow <tool>` from the repo root.
- fish plugins (tide, fisher, bass) are tracked in the repo, so they work offline. Don't copy fish's own functions into `fish/functions/`; they shadow the system ones and go stale.
- `fish_variables` is machine state and is git-ignored.
- Hardware fixes that don't belong in a config live in `.scripts/` and are not installed.
