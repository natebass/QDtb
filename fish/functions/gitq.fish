function gitq --description 'Git add, commit, and push'
    set -l msg $argv
    if test -z "$msg"
        set msg "### QUICK-COMMIT ###"
    end

    git add -A
    git commit -m "$msg"
    git push
end
