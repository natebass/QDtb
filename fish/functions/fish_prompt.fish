# Finds the git root for $PWD, cached so the walk up the tree runs once per directory.
function __fish_find_git_root
    if set -q __fish_git_root_cache_pwd; and test "$__fish_git_root_cache_pwd" = "$PWD"
        test -n "$__fish_git_root_cache"; and echo $__fish_git_root_cache
        return
    end

    set -l dir $PWD
    while test -n "$dir"; and test "$dir" != /
        # -e, not -d: a worktree or submodule has a .git file.
        if test -e "$dir/.git"
            set -g __fish_git_root_cache $dir
            set -g __fish_git_root_cache_pwd $PWD
            echo $dir
            return 0
        end
        set dir (path dirname $dir)
    end

    set -g __fish_git_root_cache ""
    set -g __fish_git_root_cache_pwd $PWD
    return 1
end

# True when any of the named marker files sits in the repo root or the current directory.
function __fish_project_has --argument-names root
    for dir in $root $PWD
        for marker in $argv[2..]
            test -f "$dir/$marker"; and return 0
        end
    end
    return 1
end

# Builds the runtime badges once per project and reuses them until the project changes.
# Rendering these on every prompt costs a find(1) walk plus a `node -v` and `python -V`
# spawn, which is most of what the prompt used to spend its time on.
function __fish_project_segments
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

# Red arrow when the last command failed, green when it succeeded.
function __fish_get_arrow_color --argument-names code
    if test -n "$code"; and test "$code" -ne 0
        set_color -o red
        return
    end
    set_color -o green
end

# Executed every time a new prompt is needed.
function fish_prompt
    # $status belongs to the last command only until something else runs, so it has to
    # be captured before anything below touches it.
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
