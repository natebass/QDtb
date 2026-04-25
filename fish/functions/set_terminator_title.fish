# function set_terminator_title
#     if test "$TERM" = "xterm-256color" -a "$COLORTERM" = "terminator"
#         xdotool set_window --shell "active" "$argv"
#     end
# end
# function set_terminator_title
#     # Check if we are in Terminator
#     if test "$TERM" = "xterm-256color" -a "$COLORTERM" = "terminator"
#         # Ensure there is an argument; default to 'fish' if empty
#         set -l title (test -n "$argv"; and echo "$argv"; or echo "fish")
#
#         # Use xdotool to set the name of the active window
#         # We use --name to target the window title specifically
#         xdotool set_window --name "$title" (xdotool getactivewindow)
#     end
# end
#
# function set_terminator_title
#     # Check if we are actually in Terminator
#     if test "$TERM" = "xterm-256color" -a "$COLORTERM" = "terminator"
#         # If no argument is passed, use the current directory name
#         set -l title "$argv"
#         if test -z "$title"
#             set title (basename (pwd))
#         end
#
#         # Set the window title (using --name is more reliable for the title bar)
#         xdotool set_window --name "$title" (xdotool getactivewindow) 2>/dev/null
#     end
# end


# function set_terminator_title
#     if test "$COLORTERM" = "truecolor" -o "$COLORTERM" = "terminator"
#         set -l title "$argv"
#         if test -z "$title"
#             set title (basename (pwd))
#         end
#         printf '\033]0;%s\007' $title
#     end
# end

# function set_terminator_title
#     # Check if we are in Terminator
#     if test "$COLORTERM" = "terminator"
#         # Get the ID of the window currently in focus
#         set -l window_id (xdotool getactivewindow)
#
#         # Determine the title: Use $argv if provided, otherwise the folder name
#         set -l title (test -n "$argv"; and echo "$argv"; or basename (pwd))
#
#         # Force the name and the icon name (some Taskbars use icon name)
#         xdotool set_window --name "$title" $window_id
#         xdotool set_window --icon-name "$title" $window_id
#     end
# end

# function set_terminator_title
#     # Check if we are in Terminator
#     if test "$COLORTERM" = "terminator"
#         # Determine the title: Use $argv if provided, otherwise the folder name
#         set -l title (test -n "$argv"; and echo "$argv"; or basename (pwd))
#
#         # Use the exact one-liner syntax you confirmed works
#         # We redirect stderr to dev/null to keep the prompt clean
#         xdotool getactivewindow set_window --name "$title" 2>/dev/null
#     end
# end
