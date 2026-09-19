
function fish_title --description 'A title that uses the built in prompt_pwd to shorten the pathname and include and git branch'
    set -l path (prompt_pwd)

    set -l command $argv[1]

    set -l git_info ""

    if command git rev-parse --is-inside-work-tree >/dev/null 2>&1
        set -l branch (command git rev-parse --abbrev-ref HEAD 2>/dev/null)
        set -l remote (command git remote | head -n 1)

        if test -n "$branch"
            if test -n "$remote"
                set git_info " | $branch@$remote"
            else
                set git_info " | $branch"
            end
        end
    end

    echo "$path$git_info"
end