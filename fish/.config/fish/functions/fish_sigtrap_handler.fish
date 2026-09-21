function fish_sigtrap_handler --description 'TRAP handler: debug prompt' --no-scope-shadowing --on-signal SIGTRAP
    breakpoint
end
