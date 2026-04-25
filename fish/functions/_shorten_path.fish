# Helper function to shorten the current working directory path.
# Each component of the path (except for the root '/' or home '~')
# will be shortened to its first letter.
function _shorten_path
    # Get the full path, using prompt_pwd to handle home directory abbreviation (~)
    set -l full_path (prompt_pwd)

    # Handle special cases for root and home directory
    if test "$full_path" = "/"
        echo "/"
        return
    end
    if test "$full_path" = "~"
        echo "~"
        return
    end

    # Split the path into individual components
    set -l parts (string split '/' "$full_path")
    set -l shortened_parts

    # Iterate through each part and shorten it
    for part in $parts
        if test "$part" = "~"
            # Keep the home directory symbol as is
            set shortened_parts $shortened_parts "~"
        else if test -n "$part"
            # If the part is not empty, take its first character
            set shortened_parts $shortened_parts (string sub -l 1 "$part")
        else
            # This handles the leading empty string for absolute paths (e.g., /a/b/c)
            # which results from splitting "/a/b/c" by '/' into "", "a", "b", "c".
            set shortened_parts $shortened_parts ""
        end
    end

    # Join the shortened parts back together with '/'
    echo (string join '/' $shortened_parts)
end

