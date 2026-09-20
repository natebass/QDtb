--- General utility functions and miscellaneous commands.
--- @module "lib.utility"
local M = {}
--- Repeats a Vim command a specified number of times.
--- If no count is provided via `vim.v.count`, it executes the command once.
--- @param cmd string The Vim command to repeat.
function M.RepeatCmd(cmd)
	local n = vim.v.count > 0 and vim.v.count or 1
	for _ = 1, n do
		vim.cmd(cmd)
	end
end

--- Wraps text to a maximum line width, breaking on whitespace.
--- @param text string The text to wrap.
--- @param limit number The maximum line width in characters.
--- @return table A list of wrapped lines.
function M.wrap_text(text, limit)
	local lines = {}
	local current_line = ""
	for word in text:gmatch("%S+") do
		if #current_line + #word + 1 > limit then
			table.insert(lines, current_line)
			current_line = word
		elseif current_line == "" then
			current_line = word
		else
			current_line = current_line .. " " .. word
		end
	end
	if current_line ~= "" then
		table.insert(lines, current_line)
	end
	return lines
end

function M.reload_config()
	local modules = {
		"Neovim",
		"plugins.plugins_mini",
		"plugins.plugins_other",
		"core.all",
		"core.autocmd",
		"core.code_style",
		"core.keymaps",
		"core.options",
		"core.other",
		"plugins.QDtb.colorscheme_cycler",
		"plugins.QDtb.package_json",
		"plugins.QDtb.window_title",
		"plugins.QDtb.autosave",
		"plugins.session_manager.session_manager",
	}

	-- 1. Unload modules using correct require paths (no leading 'lua.')
	for _, mod in ipairs(modules) do
		package.loaded[mod] = nil
	end

	-- 2. Use vim.cmd.source with runtime pathing instead of hardcoded Windows OS paths
	local ok, keymaps = pcall(require, "core.keymaps")
	if ok and type(keymaps) == "table" and keymaps.setup then
		keymaps.setup()
		vim.notify("Reloaded and reapplied keymaps.", vim.log.levels.INFO)
	else
		-- Find and source the file dynamically relative to your stdpath('config')
		local keymaps_path = vim.fn.stdpath("config") .. "/lua/core/keymaps.lua"
		vim.cmd.source(keymaps_path)
		vim.notify("Reloaded keymaps by sourcing file.", vim.log.levels.INFO)
	end
end

-- Cached system detection.
local sysname = vim.uv.os_uname().sysname

M.is_windows = sysname == "Windows_NT"
M.is_mac = sysname == "Darwin"
M.is_linux = sysname == "Linux"

return M
