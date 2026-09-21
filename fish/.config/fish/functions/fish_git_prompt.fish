function fish_git_prompt --description 'Prompt function for Git'
    # If git isn't installed, there's nothing we can do
    # Return 1 so the calling prompt can deal with it
    if not command -sq git
        return 1
    end
    # Fail if __fish_git_prompt_ready is defined and fails.
    if functions -q __fish_git_prompt_ready && not __fish_git_prompt_ready
        return 1
    end
    set -l repo_info (command git rev-parse --git-dir --is-inside-git-dir --is-bare-repository --is-inside-work-tree HEAD 2>/dev/null)
    test -n "$repo_info"
    or return

    set -l git_dir $repo_info[1]
    set -l inside_gitdir $repo_info[2]
    set -l bare_repo $repo_info[3]
    set -l inside_worktree $repo_info[4]
    set -q repo_info[5]
    and set -l sha $repo_info[5]

    set -l rbc (__fish_git_prompt_operation_branch_bare $repo_info)
    set -l r $rbc[1] # current operation
    set -l b $rbc[2] # current branch
    set -l detached $rbc[3]
    set -l dirtystate #dirty working directory
    set -l stagedstate #staged changes
    set -l invalidstate #staged changes
    set -l stashstate #stashes
    set -l untrackedfiles #untracked
    set -l c $rbc[4] # bare repository
    set -l p #upstream
    set -l informative_status

    set -q __fish_git_prompt_status_order
    or set -g __fish_git_prompt_status_order stagedstate invalidstate dirtystate untrackedfiles stashstate

    if not set -q ___fish_git_prompt_init
        # This takes a while, so it only needs to be done once,
        # and then whenever the configuration changes.
        __fish_git_prompt_validate_chars
        __fish_git_prompt_validate_colors
        set -g ___fish_git_prompt_init
    end

    set -l space "$___fish_git_prompt_color$___fish_git_prompt_char_stateseparator$___fish_git_prompt_color_done"

    # Use our variables as defaults, but allow overrides via the local git config.
    # That means if neither is set, this stays empty.
    #
    # So "!= true" or "!= false" are useful tests if you want to do something by default.
    set -l informative
    set -l dirty
    set -l untracked
    command git config -z --get-regexp 'bash\.(showInformativeStatus|showDirtyState|showUntrackedFiles)' 2>/dev/null | while read -lz key value
        switch $key
            case bash.showinformativestatus
                set informative $value
            case bash.showdirtystate
                set dirty $value
            case bash.showuntrackedfiles
                set untracked $value
        end
    end

    # If we don't print these, there is no need to compute them. Note: For now, staged and dirty are coupled.
    if not set -q dirty[1]
        contains -- "$__fish_git_prompt_showdirtystate" yes true 1
        and set dirty true
    end
    contains dirtystate $__fish_git_prompt_status_order || contains stagedstate $__fish_git_prompt_status_order
    or set dirty false

    if not set -q untracked[1]
        contains -- "$__fish_git_prompt_showuntrackedfiles" yes true 1
        and set untracked true
    end
    contains untrackedfiles $__fish_git_prompt_status_order
    or set untracked false

    if test true = $inside_worktree
        # Use informative status if it has been enabled locally, or it has been
        # enabled globally (via the fish variable) and dirty or untracked are not false.
        #
        # This is to allow overrides for the repository.
        if test "$informative" = true
            or begin
                contains -- "$__fish_git_prompt_show_informative_status" yes true 1
                and test "$dirty" != false
            end
            set informative_status (untracked=$untracked __fish_git_prompt_informative_status $git_dir)
            if test -n "$informative_status"
                set informative_status "$space$informative_status"
            end
        else
            if not test "$dirty" = true; and test "$untracked" = true
                # Only untracked, ls-files is faster.
                command git -c core.fsmonitor= ls-files --others --exclude-standard --directory --no-empty-directory --error-unmatch -- :/ >/dev/null 2>&1
                and set untrackedfiles 1
            else if test "$dirty" = true
                # With both dirty and untracked, git status is ~10% faster.
                # With just dirty, it's ~20%.
                set -l opt -uno
                test "$untracked" = true; and set opt -unormal
                # Don't use `--ignored=no`; it was introduced in Git 2.16, from January 2018
                # Ignored files are omitted by default
                set -l stat (command git -c core.fsmonitor= status --porcelain -z $opt | string split0)

                set dirtystate (string match -qr '^.[ACDMR]' -- $stat; and echo 1)
                if test -n "$sha"
                    set stagedstate (string match -qr '^[ACDMR].' -- $stat; and echo 1)
                else
                    set invalidstate 1
                end

                test "$untracked" = true
                and set untrackedfiles (string match -qr '\?\?' -- $stat; and echo 1)
            end

            if contains -- "$__fish_git_prompt_showstashstate" yes true 1
                and test -r $git_dir/logs/refs/stash
                # If we have informative status but don't want to actually
                # *compute* the informative status, we might still count the stash.
                if contains -- "$__fish_git_prompt_show_informative_status" yes true 1
                    set stashstate (count < $git_dir/logs/refs/stash)
                else
                    set stashstate 1
                end
            end
        end

        # (showupstream has a variety of options, not just bool)
        if set -q __fish_git_prompt_showupstream
            or contains -- "$__fish_git_prompt_show_informative_status" yes true 1
            set p (__fish_git_prompt_show_upstream)
        end
    end

    set -l branch_color $___fish_git_prompt_color_branch
    set -l branch_done $___fish_git_prompt_color_branch_done
    if contains -- "$__fish_git_prompt_showcolorhints" yes true 1
        if test $detached = yes
            set branch_color $___fish_git_prompt_color_branch_detached
            set branch_done $___fish_git_prompt_color_branch_detached_done
        else if test -n "$dirtystate$untrackedfiles"; and set -q __fish_git_prompt_color_branch_dirty
            set branch_color (set_color $__fish_git_prompt_color_branch_dirty)
            set branch_done (set_color $__fish_git_prompt_color_branch_dirty_done)
        else if test -n "$stagedstate"; and set -q __fish_git_prompt_color_branch_staged
            set branch_color (set_color $__fish_git_prompt_color_branch_staged)
            set branch_done (set_color $__fish_git_prompt_color_branch_staged_done)
        end
    end

    set -l f ""
    for i in $__fish_git_prompt_status_order
        if test -n "$$i"
            set -l color_var ___fish_git_prompt_color_$i
            set -l color_done_var ___fish_git_prompt_color_{$i}_done
            set -l symbol_var ___fish_git_prompt_char_$i

            set -l color $$color_var
            set -l color_done $$color_done_var
            set -l symbol $$symbol_var

            # If we count some things, print the number
            # This won't be done if we actually do the full informative status
            # because that does the printing.
            contains -- "$__fish_git_prompt_show_informative_status" yes true 1
            and set f "$f$color$symbol$$i$color_done"
            or set f "$f$color$symbol$color_done"
        end
    end

    set b (string replace refs/heads/ '' -- $b)
    if string match -qr '^\d+$' "$__fish_git_prompt_shorten_branch_len"
        set -q __fish_git_prompt_shorten_branch_char_suffix
        and set -l char -c "$__fish_git_prompt_shorten_branch_char_suffix"
        set b (string shorten -m "$__fish_git_prompt_shorten_branch_len" $char -- "$b")
    end
    if test -n "$b"
        set b "$branch_color$b$branch_done"
        if test -z "$dirtystate$untrackedfiles$stagedstate"; and test -n "$___fish_git_prompt_char_cleanstate"
            and not contains -- "$__fish_git_prompt_show_informative_status" yes true 1
            set b "$b$___fish_git_prompt_color_cleanstate$___fish_git_prompt_char_cleanstate$___fish_git_prompt_color_cleanstate_done"
        end
    end
    if test -n "$c"
        set c "$___fish_git_prompt_color_bare$c$___fish_git_prompt_color_bare_done"
    end
    if test -n "$r"
        set r "$___fish_git_prompt_color_merging$r$___fish_git_prompt_color_merging_done"
    end
    if test -n "$p"
        set p "$___fish_git_prompt_color_upstream$p$___fish_git_prompt_color_upstream_done"
    end

    # Formatting
    if test -n "$f"
        set f "$space$f"
    end
    set -l format $argv[1]
    if test -z "$format"
        set format " (%s)"
    end

    printf "%s$format%s" "$___fish_git_prompt_color_prefix" "$___fish_git_prompt_color_prefix_done$c$b$f$r$p$informative_status$___fish_git_prompt_color_suffix" "$___fish_git_prompt_color_suffix_done"
end
