set -q EDITOR; or set -gx EDITOR nvim
set -q VISUAL; or set -gx VISUAL $EDITOR

if status is-interactive
    set fish_greeting

    abbr -a g git
    abbr -a ga 'git add'
    abbr -a gc 'git commit'
    abbr -a gd 'git diff'
    abbr -a gds 'git diff --staged'
    abbr -a gl 'git pull'
    abbr -a gp 'git push'
    abbr -a gst 'git status'
    abbr -a gsw 'git switch'
    abbr -a lg lazygit

    # Ctrl-R history, Ctrl-T files, Alt-C cd. Needs fzf >= 0.48; older ones print nothing to source.
    type -q fzf; and fzf --fish 2>/dev/null | source
end

# PATH. fish_add_path -g skips duplicates and directories that don't exist, so
# this stays portable across PCs. Prepended: go, bun. Appended: the rest.
set -gx BUN_INSTALL $HOME/.bun
fish_add_path -g /usr/local/go/bin $BUN_INSTALL/bin
fish_add_path -ga /opt/nvim-linux-x86_64/bin $HOME/.local/bin $HOME/.npm-global/bin \
    $HOME/.opencode/bin $HOME/.lmstudio/bin \
    $HOME/.espressif/tools/tools/qemu-xtensa/esp_develop_9.2.2_20260417/qemu/bin
