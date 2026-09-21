function fish_svn_prompt --description 'Prompt function for svn'
    # if svn isn't installed or doesn't offer svnversion then don't do anything
    if not command -sq svn svnversion
        return 1
    end

    # make sure that this is a svn repo
    set -l checkout_info (command svn info 2>/dev/null)
    or return

    # get the current revision number
    printf '(%s%s%s' (set_color $__fish_svn_prompt_color_revision) (__fish_print_svn_rev) (set_color normal)

    # resolve the status of the checkout
    # 1. perform `svn status`
    # 2. remove extra lines that aren't necessary
    # 3. cut the output down to the first 7 columns, as these contain the information needed
    set -l svn_status_lines (command svn status | sed -e 's=^Summary of conflicts.*==' -e 's=^  Text conflicts.*==' -e 's=^  Property conflicts.*==' -e 's=^  Tree conflicts.*==' -e 's=.*incoming .* upon update.*==' | cut -c 1-7)

    # track the last column to contain a status flag
    set -l last_column 0

    # iterate over the 7 columns of output (the 7 columns are defined on `svn help status`)
    for col in (seq 7)
        # get the output for a particular column
        # 1. echo the whole status flag text
        # 2. cut out the current column of characters
        # 3. remove duplicates
        # 4. remove spaces
        set -l column_status (printf '%s\n' $svn_status_lines | cut -c $col | sort -u | tr -d ' ')

        # check that the column status list does not only contain an empty element (if it does, this column is empty)
        if test (count $column_status) -gt 1 -o -n "$column_status[1]"

            # parse the status flags for this column and create the formatting by calling out to the helper function
            set -l svn_status_flags (__fish_svn_prompt_parse_status $column_status)

            # the default separator is empty
            set -l prompt_separator ""
            for index in (seq (math "$col - $last_column"))
                # the prompt separator variable has to be updated with the number of separators needed to represent empty status columns (eg: if a file has the status "A  +" then it should display as "A|||+" in the prompt)
                set prompt_separator $prompt_separator$__fish_svn_prompt_char_separator
            end

            # record that the current column was the last one printed to the prompt
            set last_column $col
            # print the separator string then the current column's status flags
            printf '%s%s' $prompt_separator $svn_status_flags
        end
    end

    # print the close of the svn status prompt
    printf ')'
end
