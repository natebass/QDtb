vim.g.startify_lists = {
	{ type = 'sessions',           header = { ' Sessions' } },
	{ type = 'dir',                header = { ' Recent in Current Directory (' .. vim.fn.getcwd() .. ')' } },
	{ type = 'files',              header = { ' Recently Opened' } },
	{ type = 'commands',           header = { ' Custom Commands' } },
	-- Example of a custom function to list git modified files
	-- This uses a Lua function directly, which is the correct way for dynamic lists in Lua.
	-- {
	--   type = function()
	--     local output = vim.fn.system('git ls-files -m 2>/dev/null')
	--     local files = {}
	--     for line in string.gmatch(output, '([^\n]+)') do
	--       if line:find('^%s*$') == nil then
	--         table.insert(files, { line = line, path = line })
	--       end
	--     end
	--     return files
	--   end,
	--   header = { ' Git Modified Files' }
	-- },
	-- -- Example of a custom function to list git untracked files
	-- {
	--   type = function()
	--     local output = vim.fn.system('git ls-files -o --exclude-standard 2>/dev/null')
	--     local files = {}
	--     for line in string.gmatch(output, '([^\n]+)') do
	--       if line:find('^%s*$') == nil then
	--         table.insert(files, { line = line, path = line })
	--       end
	--     end
	--     return files
	--   end,
	--   header = { ' Git Untracked Files' }
	-- },
	{ type = 'bookmarks',          header = { ' Bookmarks' } },
}
-- --- Session Management ---
-- Enable session saving on exit.
-- Requires `mhinz/vim-session` or similar for full functionality if you want
-- to persist sessions outside of Startify's basic handling.
-- Startify integrates with `:mksession` by default.
vim.g.startify_session_dir = vim.fn.stdpath('data') .. '/sessions'
vim.g.startify_session_autoload = 1     -- Load session if one exists in the current directory
vim.g.startify_session_delete_entry = 1 -- Delete sessions when the project directory is removed
vim.g.startify_enable_special = 0
-- vim.g.startify_files_number = 10
vim.g.startify_change_to_dir = 0
vim.g.startify_custom_header = {}
-- --- Highlighting ---
-- You can customize the highlighting of different Startify elements.
-- These are Vim highlight group names.
vim.cmd [[highlight link StartifyHeader Normal]]
vim.cmd [[highlight link StartifySection Header]] -- Or another highlight group
vim.cmd [[highlight link StartifyFile Comment]]
vim.cmd [[highlight link StartifyBracket Normal]]
vim.cmd [[highlight link StartifyNumber Comment]]
vim.cmd [[highlight link StartifyPath Comment]]
vim.cmd [[highlight link StartifySelect Normal]]
-- You might want to define custom highlight groups if your colorscheme doesn't have them
-- For example:
-- vim.api.nvim_set_hl(0, 'StartifyHeader', { fg = '#8be9fd', bg = 'NONE', bold = true })
-- vim.api.nvim_set_hl(0, 'StartifySection', { fg = '#bd93f9', bg = 'NONE', bold = true })

-- --- General Settings ---
-- Disable the default special buffers (help, intro, etc.)
-- vim.g.startify_enable_special = 0
-- Number of recent files to display
-- vim.g.startify_files_number = 10
-- Don't change the current working directory to the project directory
-- vim.g.startify_change_to_dir = 0
-- --- Header and Footer ---
-- Custom header (ASCII art, motivational quotes, etc.)
-- Use a table of strings, each representing a line.
-- You can use `[[ ]]` for multiline strings in Lua to avoid escaping issues.
-- vim.g.startify_custom_header = {}
-- Custom footer (optional)
-- vim.g.startify_custom_footer = require('quotes').quotes()
-- vim.g.startify_session_dir = '/home/nwb/.var/app/dev.neovide.neovide/config/nvim/session'
-- --- Bookmarks ---
-- vim.g.startify_bookmarks = {
-- 	{ R = '~/Source/Repos' },
-- 	{ r = '/home/nwb/.var/app/dev.neovide.neovide/config/nvim/init.lua' },
-- 	{ w = '/home/nwb/.var/app/dev.neovide.neovide/config/nvim/init.lua' },
-- 	{ f = '/home/nwb/.var/app/dev.neovide.neovide/config/nvim/init.lua' },
-- 	{ d = '/home/nwb/.var/app/dev.neovide.neovide/config/nvim/init.lua' },
-- 	{ e = '/home/nwb/.var/app/dev.neovide.neovide/config/nvim/init.lua' },
-- 	{ s = '~/OneDrive/Documents/Adtb/Past/IntelliJ.txt' },
-- 	{ j = '~/Source/Repos/fe-innovcal-web/package.json' },
-- 	{ l = '~/OneDrive/Documents/Adtb/Past/Windows IntelliJ.txt' },
-- 	{ W = '~/OneDrive/Documents/Adtb/Windows.lua' },
-- 	{ t = '~/OneDrive/Documents/Adtb/Snippets.json' },
-- 	{ z = '~/OneDrive/Documents/Adtb/Abbreviations.lua' },
-- 	{ p = '~/OneDrive/Documents/PowerShell/Microsoft.Powershell_profile.ps1' },
-- 	{ x = '~/Source/Repos/' },
-- }
