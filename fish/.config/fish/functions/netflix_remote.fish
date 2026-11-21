function netflix_remote --description "Launch the Netflix desktop entry"
    set -gx XAUTHORITY $HOME/.Xauthority
    gtk-launch Netflix $argv
end
