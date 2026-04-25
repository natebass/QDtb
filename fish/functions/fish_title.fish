
function fish_title
    set -l path (_long_path (pwd))

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

    if test "$command" = "fish"
        echo "$path$git_info"
    else
        echo "$path$git_info"
    end
end
