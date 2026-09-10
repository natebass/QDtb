# History expansion helpers, plus the abbreviations that use them.
# Called from conf.d/20-history-abbrs.fish, which autoloads this file and
# thereby defines the _*_history_item functions the abbrs expand through.
function better_history --description 'Register history expansion abbreviations'
    abbr -a !! --position anywhere --function _last_history_item
    abbr -a 2 --position anywhere --function _second_to_last_history_item
    abbr -a 3 --position anywhere --function _third_to_last_history_item
end

function _last_history_item
    echo $history[2]
end

function _second_to_last_history_item
    echo $history[3]
end

function _third_to_last_history_item
    echo $history[4]
end
