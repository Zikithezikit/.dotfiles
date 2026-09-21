function disown
    set -l jobbltn disown
        builtin $jobbltn (__fish_expand_pid_args $argv)
    
end
