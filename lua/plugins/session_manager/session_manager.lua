--- Configure Startify for session management, custom headers, and bookmarks.
--- @module "plugins.session_manager.session_manager"
local g = vim.g
-- General Settings {{{
g.startify_enable_special = 0 -- Disable the default special buffers (help, intro, etc.).
g.startify_files_number = 10 -- Number of recent files to display.
g.startify_change_to_dir = 0 -- Don't change the current working directory to the project directory.
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
vim.g.startify_bookmarks = {
	{ R = vim.fn.expand("~/Source/Repos") },
	{ r = "/home/nwb/.var/app/dev.neovide.neovide/config/nvim/init.lua" },
	{ w = "/home/nwb/.var/app/dev.neovide.neovide/config/nvim/init.lua" },
	{ f = "/home/nwb/.var/app/dev.neovide.neovide/config/nvim/init.lua" },
	{ d = "/home/nwb/.var/app/dev.neovide.neovide/config/nvim/init.lua" },
	{ e = "/home/nwb/.var/app/dev.neovide.neovide/config/nvim/init.lua" },
	{ s = "~/OneDrive/Documents/QDtb/Past/IntelliJ.txt" },
	{ j = "~/Source/Repos/fe-innovcal-web/package.json" },
	{ l = "~/OneDrive/Documents/QDtb/Past/Windows IntelliJ.txt" },
	{ W = "~/OneDrive/Documents/QDtb/Windows.lua" },
	{ t = "~/OneDrive/Documents/QDtb/Snippets.json" },
	{ z = "~/OneDrive/Documents/QDtb/Abbreviations.lua" },
	{ p = "~/OneDrive/Documents/PowerShell/Microsoft.Powershell_profile.ps1" },
	{ x = "~/Source/Repos/" },
}
-- }}}
-- Footer
-- vim:foldmethod=marker:foldlevel=1
