# ✎ Learn ------
# From your current line to the end of file:
# :.,$s/a/b/g
#
# . = current line
# $ = last line
# , separates the range
#
# If you want from line N to EOF: N,$s/a/b/g
# ← go back alt-left
# → go forward alt-right
# -------------
abbr --add Q  'fdfind -tf'
abbr --add q  'fastfetch --config ~/Downloads/a.jsonc --logo none'
abbr --add W  'fdfind -a'
abbr --add w  'exec fish'
abbr --add E  'fdfind -tf -H'
abbr --add e  'cdh'
abbr --add R  'fdfind -td'
abbr --add r  'uv run ruff format; uv run ruff check --fix; uv run ty check'
abbr --add T  'fdfind -l'
# abbr --add t  'uv sync'
abbr --add t  'vp run test'
# abbr --add A  'fdfind -tf -X rm -i'     # delete matched files (type pattern after... careful!)
abbr --add A  'eza --color=always -l --git --hyperlink --header -T Documents/ | less -R'
abbr --add a  'eza'
abbr --add S  'fdfind -0 -tf | xargs -0 wc -l'
abbr --add s  'pnpm i;'
abbr --add D  'fdfind | tree --fromfile'
abbr --add d  'git status'
# abbr --add F  'uv run ruff check --fix; uv run ruff format;'
abbr --add F  'pnpm lint:fix;'
# abbr --add f  'vp check --fix;'
abbr --add G  'eza -l --no-time --no-user --no-permissions **.txt'
abbr --add g  'pnpm dev;'
abbr --add Z  'git log --oneline -10'
abbr --add z  'git push'
abbr --add X  'git diff'
abbr --add x  'lazygit'
abbr --add C  'git remote -v'
abbr --add c  'git pull'
abbr --add V  'pnpm build;'
abbr --add v  'pnpm compile;'
abbr --add B  'zoxide query -i'
abbr --add b  'uv run --env-file .env --package app fastapi dev backend/app/main.py'
abbr --add 1  'cd -'
abbr --add 4  'history --max 3'
abbr --add 5  'pnpm upgrade --latest'
abbr --add 6  'uv sync --upgrade'
abbr --add Y  'git switch'
abbr --add y  'git add -A; git commit -m'
abbr --add U  'fdfind -e'
abbr --add u  'fdfind -H'
abbr --add I  'git switch -c'
abbr --add i  'git stash'
abbr --add O  'zoxide remove'
abbr --add o  'zoxide add'
abbr --add P  'prevd'
abbr --add p  'nextd'
abbr --add H  'fdfind -t d'
abbr --add h  'git log --oneline -1'
abbr --add J  'fdfind -p'
abbr --add K  'pushd'
abbr --add k  'pnpm i'
abbr --add L  'zoxide query'
abbr --add l  'openssl rand -base64'
abbr --add - 'nvim'
abbr --add N  'fdfind -g'
abbr --add n  'dirs'
abbr --add M  'fdfind -H -I'
abbr --add m  'popd'
abbr --add ,  'pushd .'
abbr --add 7  'jq'
abbr --add 8  'rg'
abbr --add 9  'fzf'
abbr --add 0  'openssl rand -hex'
abbr --add '`' 'pwsh'
abbr -a !! --function better_history_first
abbr -a 2 --function better_history_second
abbr -a 3 --function better_history_third
abbr --add dotdot --regex '^\.\.+$' --function multicd
alias qq 'exit'
alias tmuxa 'tmux attach -t'
alias tmuxn 'tmux new -s'
# Footer {{{
# vim: ft=fish: fdm=marker: foldlevel=0
# }}}