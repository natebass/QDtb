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
local config_init = vim.fs.joinpath(vim.fn.stdpath("config"), "init.lua")
g.startify_commands = {
	{
		["u"] = { "Update Plugins", "lua vim.pack.update()" },
		["p"] = { "Plugin Status", "lua vim.print(vim.pack.get())" },
	},
	{
		["e"] = { "Edit Neovim Config", "edit " .. vim.fn.fnameescape(config_init) },
		["s"] = { "Restart Neovim", "restart" },
	},
	{
		["g"] = { "Git Status", "Git status" },
		["f"] = { "Find Files (Telescope)", "Telescope find_files" },
	},
}
-- }}}
-- List Order and Types {{{

--- Builds a Startify list provider that runs `git` with the given arguments and
--- returns one entry per reported file. Errors (no repository, no git) yield no entries.
--- @param args string[] Arguments passed to git, without the leading "git".
--- @return fun(): table[]
local function git_files(args)
	return function()
		local result = vim.system(vim.list_extend({ "git" }, args), { text = true }):wait()
		if result.code ~= 0 then
			return {}
		end
		local files = {}
		for line in (result.stdout or ""):gmatch("[^\n]+") do
			if line:match("%S") then
				table.insert(files, { line = line, path = line })
			end
		end
		return files
	end
end

g.startify_lists = {
	{ type = "dir", header = { " Recent in Current Directory (" .. vim.fn.getcwd() .. ")" } },
	{ type = "files", header = { " Recently Opened" } },
	{ type = "sessions", header = { " Sessions" } },
	{ type = "bookmarks", header = { " Bookmarks" } },
	{ type = "commands", header = { " Custom Commands" } },
	-- Dynamic lists backed by git. vim.system takes an argv list, so there is no shell
	-- to quote against and no need to redirect stderr: it is captured separately.
	{ type = git_files({ "ls-files", "-m" }), header = { " Git Modified Files" } },
	{
		type = git_files({ "ls-files", "-o", "--exclude-standard" }),
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
-- stdpath resolves to this directory under Neovide's flatpak XDG_CONFIG_HOME and to
-- the plain ~/.config/nvim elsewhere, so the bookmarks follow the config that is running.
local c = vim.fn.stdpath("config")
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
		{ w = j(c, "lua/config/unix.lua") },
		{ f = j(c, "after/plugin/keymaps.lua") },
		{ d = j(c, "fish/config.fish") },
		{ E = e("~/Source/Repos") },
		{ m = j(c, "after/plugin/mini.lua") },
		{ s = j(c, "IntelliJ/ideavimrc.txt") },
		{ l = j(c, "IntelliJ/windows.txt") },
		{ z = j(c, "plugin/packages.lua") },
		{ p = j(c, "lua/plugins/session_manager/session_manager.lua") },
		{ x = j(c, "fish/conf.d/abbreviations.fish") },
		{ u = j(c, "lua/lib/utility.lua") },
	}
end
-- }}}
-- Footer
-- vim:foldmethod=marker:foldlevel=1
