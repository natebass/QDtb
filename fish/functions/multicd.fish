# Adding an abbreviation is required /home/nwb/.config/fish/conf.d/abbreviations.fish
# abbr --add dotdot --regex '^\.\.+$' --function multicd
function multicd
    echo cd (string repeat -n (math (string length -- $argv[1]) - 1) ../)
end
