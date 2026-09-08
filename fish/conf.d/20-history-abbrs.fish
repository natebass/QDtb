# History expansion abbreviations
function _last_history_item
    echo $history[2]
end

function _second_to_last_history_item
    echo $history[3]
end

function _third_to_last_history_item
    echo $history[4]
end

abbr -a !! --position anywhere --function _last_history_item
abbr -a 2  --position anywhere --function _second_to_last_history_item
abbr -a 3  --position anywhere --function _third_to_last_history_item