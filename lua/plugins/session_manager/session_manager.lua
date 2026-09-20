--- Configure Startify for session management, custom headers, and bookmarks.
--- @module "plugins.session_manager.session_manager"
local utils = require("lib.utility")
local g = vim.g
-- General Settings {{{
g.startify_enable_special = 0
g.startify_files_number = 10
g.startify_change_to_dir = 0
g.startify_custom_header = require("plugins.session_manager.bible_verse").quotes()
g.startify_custom_footer = require("plugins.session_manager.algorithm_quote").quotes()
-- Custom Commands {{{
g.startify_commands = {
	{
		["u"] = { "Update Plugins", "Lazy sync" },
		["p"] = { "Packer Compile", "PackerCompile" },
	},
	{
		["e"] = { "Edit Neovim Config", "e ~/.config/nvim/init.lua" },
		["s"] = { "Source Config", "source ~/.config/nvim/init.lua" },
	},
	{
		["g"] = { "Git Status", "Gitsigns status_buffered" },
		["f"] = { "Find Files (Telescope)", "Telescope find_files" },
	},
}
-- }}}
-- List Order and Types {{{
g.startify_lists = {
	{ type = "dir", header = { " Recent in Current Directory (" .. vim.fn.getcwd() .. ")" } },
	{ type = "files", header = { " Recently Opened" } },
	{ type = "sessions", header = { " Sessions" } },
	{ type = "bookmarks", header = { " Bookmarks" } },
	{ type = "commands", header = { " Custom Commands" } },
	-- Example of a custom function to list git modified files
	-- This uses a Lua function directly, which is the correct way for dynamic lists in Lua.
	{
		type = function()
			local output = vim.fn.system("git ls-files -m 2>/dev/null")
			local files = {}
			for line in string.gmatch(output, "([^\n]+)") do
				if line:find("^%s*$") == nil then
					table.insert(files, { line = line, path = line })
				end
			end
			return files
		end,
		header = { " Git Modified Files" },
	},
	-- Example of a custom function to list git untracked files
	{
		type = function()
			local output = vim.fn.system("git ls-files -o --exclude-standard 2>/dev/null")
			local files = {}
			for line in string.gmatch(output, "([^\n]+)") do
				if line:find("^%s*$") == nil then
					table.insert(files, { line = line, path = line })
				end
			end
			return files
		end,
		header = { " Git Untracked Files" },
	},
}
-- Session Management {{{
-- Enable session saving on exit.
-- Requires `mhinz/vim-session` or similar for full functionality if you want
-- to persist sessions outside of Startify's basic handling.
-- Startify integrates with `:mksession` by default.
g.startify_session_dir = vim.fn.stdpath("data") .. "/sessions"
g.startify_session_autoload = 1 -- Load session if one exists in the current directory
g.startify_session_delete_entry = 1 -- Delete sessions when the project directory is removed
-- }}}
-- Highlighting {{{
vim.cmd([[highlight link StartifyHeader Normal]])
vim.cmd([[highlight link StartifySection Header]]) -- Or another highlight group
vim.cmd([[highlight link StartifyFile Comment]])
vim.cmd([[highlight link StartifyBracket Normal]])
vim.cmd([[highlight link StartifyNumber Comment]])
vim.cmd([[highlight link StartifyPath Comment]])
vim.cmd([[highlight link StartifySelect Normal]])
vim.api.nvim_create_autocmd("FileType", {
	pattern = "startify",
	callback = function()
		vim.opt_local.list = false
	end,
})
--- }}}
-- Bookmarks {{{
local e = vim.fn.expand
local j = vim.fs.joinpath
local c = e("~/.var/app/dev.neovide.neovide/config/nvim")
if utils.is_windows then
	vim.g.startify_bookmarks = {
		{ R = e("~/Source/Repos") },
		{ w = e("~/OneDrive/Documents/Adtb/Vim/Windows.lua") },
		{ r = e("~/OneDrive/Documents/Adtb/Vim/lua/config/options.lua") },
		{ s = e("~/OneDrive/Documents/Adtb/Vim/lua/plugins/session_manager/session_manager.lua") },
		{ f = e("~/OneDrive/Documents/Adtb/Vim/lua/core/keymaps.lua") },
		{ W = e("~/AppData/Local/nvim/init.lua") },
		{ l = e("~/OneDrive/Documents/Adtb/IntelliJ/Windows IntelliJ.txt") },
		{ p = e("~/OneDrive/Documents/PowerShell/Microsoft.Powershell_profile.ps1") },
	}
else
	vim.g.startify_bookmarks = {
		{ R = j(c, "powershell/Microsoft.VSCode_profile.ps1") },
		{ r = j(c, "lua/config/options.lua") },
		{ T = j(c, "powershell/Microsoft.PowerShell_profile.ps1") },
		{ t = j(c, "init.lua") },
		{ W = j(c, "snippets/Snippets.json") },
		{ w = j(c, "lua/config/Unix.lua") },
		{ f = j(c, "after/plugin/keymaps.lua") },
		{ d = j(c, "fish/config.fish") },
		{ E = e("~/Source/Repos") },
		{ e = j(c, "lua/config/Emacs/Vim/Abbreviations.vim") },
		{ s = j(c, "lua/config/Past/IntelliJ.txt") },
		{ l = j(c, "lua/config/Past/Windows IntelliJ.txt") },
		{ z = j(c, "lua/config/Abbreviations.lua") },
		{ p = j(c, "powershell/Microsoft.PowerShell_profile.ps1") },
		{ x = j(c, "lua/config/Source/Repos/") },
		{ u = j(c, "lua/lib/utility.lua") },
	}
end
-- }}}
-- Footer
-- vim:foldmethod=marker:foldlevel=1
