function _long_path --argument path
    # Replace $HOME with ~
    set -l home (string replace -r "^$HOME" "~" $path)

    # Extract all but the last component
    set -l base (dirname $home)

    # Get the last directory name and shorten to first character
    set -l last (basename $home)
    set -l short_last (string sub -s 1 -l 1 $last)

    # Combine
    echo "$base/$short_last"
end

