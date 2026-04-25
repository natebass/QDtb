# Learn
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
abbr --add dotdot --regex '^\.\.+$' --function multicd
abbr --add q  'fastfetch --config ~/Downloads/a.jsonc --logo none'
abbr --add w  'source ~/.config/fish/config.fish;clear'
abbr --add e  'cdh'
abbr --add r  'uv run ruff format; uv run ruff check --fix; uv run ty check'
abbr --add t  'uv sync'

abbr --add a  'eza --color=always -l --git --hyperlink --header -T Documents/ | less -R'
abbr --add s  'pnpm i'
abbr --add d  'git status'
abbr --add F  'uv run ruff check --fix; uv run ruff format;'
abbr --add f  'pnpm lint; pnpm format;'
abbr --add G  'eza -l --no-time --no-user --no-permissions **.txt'
abbr --add g  'pnpm dev'
abbr --add z  'git pull'
abbr --add x  'lazygit'
abbr --add C  'git remote -v'
abbr --add c  'git push'
abbr --add v  'pnpm compile'
abbr --add V  'zoxide query -i'
abbr --add B  'pnpm build'
abbr --add b  'uv run --env-file .env --package app fastapi dev backend/app/main.py'
abbr --add 1  'cd -'
abbr --add 4  'history --max 3'
abbr --add 5  'pnpm upgrade --unsafe'
abbr --add 6  'uv sync --upgrade'
#abbr --add 1  'git log --oneline -10'
#abbr --add 2  'git diff'
#abbr --add 3  'git switch'
#abbr --add 4  'git switch -c'
#abbr --add 5  'git stash'
#### Right ###
abbr --add h  'git log --oneline -1'
#abbr --add j  ''
abbr --add k  'pnpm i'
abbr --add l  'openssl rand -base64'
abbr --add - 'nvim'
abbr --add y  'git add -A; git commit -m'           
abbr --add u  'fdfind -H'            
abbr --add i  'zoxide remove'          
abbr --add o  'zoxide add'          
# abbr --add i  'prevd'          
# abbr --add o  'nextd'          
# abbr --add p  'pushd'
abbr --add p  'zoxide query'
abbr --add n  'dirs'
abbr --add m  'popd'
abbr --add ,  'pushd .'
abbr --add 7  'jq'
abbr --add 8  'rg'
abbr --add 9  'fzf'
abbr --add 0  'openssl rand -hex'
abbr --add '`' 'pwsh'


# RIGHT SIDE (requires input - trailing space, cursor ready)
# # U H J N M - right hand keys
abbr --add U  'fdfind -e '           # by extension
abbr --add H  'fdfind -t d '         # find directories
abbr --add J  'fdfind -p '           # full path match
abbr --add N  'fdfind -g '           # glob search
abbr --add M  'fdfind -H -I '        # unrestricted (hidden + no-ignore)

# # LEFT SIDE (immediate execution, just press enter)
# # Q W E R T A S D F - left hand keys
abbr --add Q  'fdfind -tf'           # list all files, current dir
abbr --add W  'fdfind -a'            # list all, absolute paths
abbr --add E  'fdfind -tf -H'        # all files including hidden
abbr --add R  'fdfind -td'           # list all directories
abbr --add T  'fdfind -l'            # list with details (like ls -l)
abbr --add A  'fdfind -tf -X rm'     # delete matched files (type pattern after... careful!)
abbr --add S  'fdfind -0 -tf | xargs -0 wc -l'   # count lines in all files
abbr --add D  'fdfind | tree --fromfile'          # show as tree





abbr --add qq 'exit'


# Features
# interactive history picker
# print history list
# toggle last two dirs (builtin fish)
# ← go back  (mirrors alt-left)
# → go forward (mirrors alt-right)
# . and / — skipped (shell/path special chars, too error-prone as abbrs)
