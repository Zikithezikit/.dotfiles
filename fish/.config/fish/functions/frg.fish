function frg --description "Live interactive ripgrep + fzf preview"
    set -l initial_query (string escape -- $argv)

    set -l rg_command "rg --column --line-number --no-heading --color=always --smart-case --hidden --glob '!.git/*'"

    # Clipboard fallback (supports Wayland, X11, macOS)
    set -l copy_cmd pbcopy
    if type -q wl-copy
        set copy_cmd wl-copy
    else if type -q xclip
        set copy_cmd "xclip -selection clipboard"
    end

    # Ubuntu ships bat as `batcat`
    set -l bat bat
    type -q bat; or set bat batcat

    set -l result (
        FZF_DEFAULT_COMMAND="$rg_command ''" \
        fzf --disabled \
            --ansi \
            --query="$initial_query" \
            --delimiter ':' \
            --prompt '🔍 Search > ' \
            --header '⚡ [Ctrl-Y: Copy Preview] | Search file contents' \
            --border='rounded' \
            --border-label=' Live Ripgrep Search ' \
            --border-label-pos='2' \
            --color='border:#89b4fa,label:#f5e0dc,prompt:#cba6f7,pointer:#f5e0dc' \
            --preview "test -n '{1}' && $bat --style=numbers,changes --color=always --highlight-line {2} -- {1}" \
            --preview-window 'right:60%,border-rounded,+{2}+3/3' \
            --bind "start:reload:$rg_command {q}" \
            --bind "change:reload:$rg_command {q} || true" \
            --bind "ctrl-y:execute-silent($bat --plain --color=never -- {1} | $copy_cmd)+change-prompt(📋 Copied! > )"
    )

    if test -n "$result"
        set -l file (string split -f1 ":" -- $result)
        set -l line (string split -f2 ":" -- $result)

        set -l editor $EDITOR
        test -z "$editor"; and set editor nvim

        $editor +$line "$file"
    end
end
