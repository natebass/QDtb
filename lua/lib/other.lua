--- Other Utilities.
--- Contains miscellaneous utility functions and commands.
--- @module config.other

--- Repeats a Vim command a specified number of times.
--- If no count is provided via `vim.v.count`, it executes the command once.
--- @param cmd string The Vim command to repeat.
-- Repeat command function in Lua
local function RepeatCmd(cmd)
	local n = vim.v.count > 0 and vim.v.count or 1
	for _ = 1, n do
		vim.cmd(cmd)
	end
end
-- Footer
-- vim:foldmethod=marker:foldlevel=1
