function gitq --description 'Git add, commit, and push'
    set -l msg $argv
    if test -z "$msg"
        set msg "### QUICK-COMMIT ###"
    end

    git add -A
    git commit -m "$msg"
    git push
end

# function tmuxa {
# 	tmux a -t $1
# }

# function tmuxn {
# 	tmux new -s $1
# }

# function c {
# 	if (( $# == 0 )) then 
# 		ls 
# 	else
# 		cd "$@" && ls
# 	fi
# }