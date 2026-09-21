function wait
    set -l jobbltn wait
        builtin $jobbltn (__fish_expand_pid_args $argv)
    
end
