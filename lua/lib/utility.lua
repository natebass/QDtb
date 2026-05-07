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

return M
