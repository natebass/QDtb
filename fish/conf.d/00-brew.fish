# Initialize Homebrew
# if test -d /home/linuxbrew/.linuxbrew/bin
#     eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv fish)"

#     # Completions
#     set -l brew_prefix (brew --prefix)
#     if test -d "$brew_prefix/share/fish/completions"
#         set -p fish_complete_path "$brew_prefix/share/fish/completions"
#     end
#     if test -d "$brew_prefix/share/fish/vendor_completions.d"
#         set -p fish_complete_path "$brew_prefix/share/fish/vendor_completions.d"
#     end
# end

# Save ~20ms
# if test -d /home/linuxbrew/.linuxbrew/bin
#     eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv fish)"

#     # Completions (uses $HOMEBREW_PREFIX set by brew shellenv)
#     if test -d "$HOMEBREW_PREFIX/share/fish/completions"
#         set -p fish_complete_path "$HOMEBREW_PREFIX/share/fish/completions"
#     end

#     if test -d "$HOMEBREW_PREFIX/share/fish/vendor_completions.d"
#         set -p fish_complete_path "$HOMEBREW_PREFIX/share/fish/vendor_completions.d"
#     end
# end

# Fast static Homebrew initialization (~0ms)
if test -d /home/linuxbrew/.linuxbrew
    set -gx HOMEBREW_PREFIX "/home/linuxbrew/.linuxbrew"
    set -gx HOMEBREW_CELLAR "/home/linuxbrew/.linuxbrew/Cellar"
    set -gx HOMEBREW_REPOSITORY "/home/linuxbrew/.linuxbrew/Homebrew"
    fish_add_path -g /home/linuxbrew/.linuxbrew/bin /home/linuxbrew/.linuxbrew/sbin

    # Completions
    if test -d "$HOMEBREW_PREFIX/share/fish/completions"
        set -p fish_complete_path "$HOMEBREW_PREFIX/share/fish/completions"
    end
    if test -d "$HOMEBREW_PREFIX/share/fish/vendor_completions.d"
        set -p fish_complete_path "$HOMEBREW_PREFIX/share/fish/vendor_completions.d"
    end
end