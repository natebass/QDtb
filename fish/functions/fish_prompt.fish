function __fish_find_git_root --description 'Find the git root of the current directory.'
    if set -q __fish_git_root_cache_pwd; and test "$__fish_git_root_cache_pwd" = "$PWD"
        test -n "$__fish_git_root_cache"; and echo $__fish_git_root_cache
        return
    end

    set -l directory $PWD
    while test -n "$directory"; and test "$directory" != /
        # Check for both files and directories named `.git` because git worktrees and submodules use a file instead of a directory.
        if test -e "$directory/.git"
            set -g __fish_git_root_cache $directory
            set -g __fish_git_root_cache_pwd $PWD
            echo $directory
            return 0
        end
        set directory (path dirname $directory)
    end

    set -g __fish_git_root_cache ""
    set -g __fish_git_root_cache_pwd $PWD
    return 1
end

function __fish_project_has --description 'Check for runtime files.' --argument-names root
    for dir in $root $PWD
        for runtime_file in $argv[2..]
            test -f "$dir/$runtime_file"; and return 0
        end
    end
    return 1
end

# Builds the runtime badges once per project and reuses them until the project changes.
# Rendering these on every prompt costs a find(1) walk plus `node -v` and `python -V`.
function __fish_project_segments --description 'Build the runtime badges.'
    set -l git_root (__fish_find_git_root)
    test -z "$git_root"; and return

    set -l key "$git_root:$PWD"
    if set -q __fish_project_cache_key; and test "$__fish_project_cache_key" = "$key"
        echo -n $__fish_project_cache
        return
    end

    set -l segments ""

    if __fish_project_has $git_root package.json; and type -q node
        set segments $segments(set_color green)"⬢ "(node -v | string replace -r '^v' '')(set_color normal)
    end

    if __fish_project_has $git_root requirements.txt setup.py pyproject.toml poetry.lock Pipfile
        set -l reported
        if type -q python
            set reported (python -V 2>&1 | string split ' ')
        else if type -q python3
            set reported (python3 -V 2>&1 | string split ' ')
        end
        if set -q reported[2]
            set segments $segments(set_color yellow)"  $reported[2]"(set_color normal)
        end
    end

    set -g __fish_project_cache_key $key
    set -g __fish_project_cache $segments
    echo -n $segments
end

function __fish_get_arrow_color --description 'Success/failure arrow color.' --argument-names code
    if test -n "$code"; and test "$code" -ne 0
        set_color -o red
        return
    end
    set_color -o green
end

function fish_prompt --description 'A minimal fish prompt with runtime badges.'
    # $status changes after every command. Capture it immediately so subsequent lines do not overwrite it.
    set -l last_status $status

    set_color blue
    echo -n " "(path basename $PWD)" "

    __fish_project_segments

    set_color normal

    set -l arrow " ➜ "
    if fish_is_root_user
        set arrow "#  "
    end

    echo -n -s (__fish_get_arrow_color $last_status) $arrow
    set_color normal
    echo -n " "
end
