# Helper function to find git root directory with caching
function __fish_find_git_root
    set -l current_pwd (pwd)
    
    # Use cached result if available and current
    if set -q __fish_git_root_cache; and test "$__fish_git_root_cache_pwd" = "$current_pwd"
        test -n "$__fish_git_root_cache" && echo $__fish_git_root_cache
        return
    end
    
    # Find git root
    set -l current_dir $current_pwd
    while test "$current_dir" != "/"
        if test -d "$current_dir/.git"
            set -g __fish_git_root_cache $current_dir
            set -g __fish_git_root_cache_pwd $current_pwd
            echo $current_dir
            return 0
        end
        set current_dir (dirname $current_dir)
    end
    
    # Cache negative result
    set -g __fish_git_root_cache ""
    set -g __fish_git_root_cache_pwd $current_pwd
    return 1
end

# Helper function to check for Node.js project
function __fish_check_node_project
    set -l git_root (__fish_find_git_root)
    if test -n "$git_root"
        if find "$git_root" -maxdepth 2 -name "package.json" -print -quit 2>/dev/null | read -l package_json
            if type -q node
                set_color green
                echo -n "⬢ "(node -v | sed 's/v//')
                set_color normal
            end
        end
    end
end

# Helper function to check for Python project
function __fish_check_python_project
    set -l git_root (__fish_find_git_root)
    if test -n "$git_root"
        if find "$git_root" -maxdepth 2 \( -name "requirements.txt" -o -name "setup.py" -o -name "pyproject.toml" -o -name "poetry.lock" -o -name "Pipfile" \) -print -quit 2>/dev/null | read -l python_file
            set -l python_version ""
            if type -q python
                set python_version (python -V 2>&1 | awk '{print $2}')
            else if type -q python3
                set python_version (python3 -V 2>&1 | awk '{print $2}')
            end
            if test -n "$python_version"
                set_color yellow
                echo -n "  $python_version"
                set_color normal
            end
        end
    end
end

# Helper function to determine arrow color based on various states
function __fish_get_arrow_color
    set -l code $__last_command_exit_status
    
	# Ensure $code is set before testing
	if test -n "$code"
		# Check for npm run dev error specifically
		if test "$code" -eq 254
		    set_color -o red
		    return
		end

		if test "$code" -eq 127
		    set_color -o red
		    return
		end

		# Red for any non-zero exit code
		if test $code -ne 0
		    set_color -o red
		    return
		end
	end
#    # Yellow for active virtual environment
#    if test -n "$VIRTUAL_ENV"
#        set_color -o yellow
#        return
#    end
#    
#    # Cyan for running dev servers (check common dev ports)
#    for port in 3000 5173 8000 8080
#        if lsof -ti:$port 2>/dev/null | read -l pid
#            set_color -o cyan
#            return
#        end
#    end
#    
#    # Blue for git repositories
#    if __fish_find_git_root >/dev/null 2>&1
#        set_color -o blue
#        return
#    end
#    
#    # Default green
    set_color -o green
end

# Define the fish_prompt function, which is executed every time a new prompt is needed.
function fish_prompt
    # set_terminator_title (basename (pwd))
    # Set the color for the current working directory (e.g., blue).
    set_color blue
    # Display the shortened current working directory using our helper function.
    echo -n " "
    echo -n (basename (pwd))
    echo -n " "

    # --- Node.js Project Detection ---
    __fish_check_node_project

    # --- Python Project Detection ---
    __fish_check_python_project

    # --- Final Prompt Symbol ---
    # Reset the color to the default terminal color.
    set_color normal
    
    # Get the appropriate arrow color
    set -l arrow_color (__fish_get_arrow_color)
    
    set -l arrow " ➜ "
    if fish_is_root_user
        set arrow "#  "
    end
    
    echo -n -s $arrow_color $arrow
    set_color normal
    echo -n " "
end
