function netflix_remote --wraps=export\ XAUTHORITY=\'/home/server-yoav/.Xauthority\'\ \&\&\ gtk-launch\ Netflix --description alias\ netflix_remote=export\ XAUTHORITY=\'/home/server-yoav/.Xauthority\'\ \&\&\ gtk-launch\ Netflix
  export XAUTHORITY='/home/server-yoav/.Xauthority' && gtk-launch Netflix $argv
        
end
