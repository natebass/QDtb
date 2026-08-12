#                  ___
#   ___======____=---=)
# /T            \_--===)
# [ \ (0)   \~    \_-==)
#  \      / )J~~    \-=)
#   \\\\___/  )JJ~~~   \)
#    \_____/JJ~~~~~    \\
#    / \  , \J~~~~~     \\
#   (-\)\=|\\\\\~~~~       L__
#   (\\\\)  (\\\\\)_           \==__
#    \V    \\\\\) ===_____   \\\\\\\\\\\\
#           \V)     \_) \\\\\\\\JJ\J\)
#                       /J\JT\JJJJ)
#                       (JJJ| \UUU)
#                        (UU)'
#

# The next line updates PATH for the Google Cloud SDK.
# Google Cloud SDK 558.0.0
# bq 2.1.28
# bundled-python3-unix 3.13.10
# core 2026.02.20
# gcloud-crc32c 1.0.0
# gsutil 5.35
# if [ -f '/home/nwb/Downloads/google-cloud-sdk/path.fish.inc' ]; . '/home/nwb/Downloads/google-cloud-sdk/path.fish.inc'; end


# luarocks
# set -gx LUA_PATH (luarocks path --lr-path)
# set -gx LUA_CPATH (luarocks path --lr-cpath)
# fish_add_path (luarocks path --bin | grep -oP '(?<=PATH=)[^;]+')

function last_history_item
    echo $history[2]
end

function second_to_last_history_item
    echo $history[3]
end

function third_to_last_history_item
    echo $history[4]
end

abbr -a 2 --function second_to_last_history_item
abbr -a 3 --function third_to_last_history_item
abbr -a !! --position anywhere --function last_history_item


# Must be at the end due to source command.
zoxide init fish --cmd j | source
