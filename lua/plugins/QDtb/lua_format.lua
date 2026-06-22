--- Stylua Formatting Integration.
--- Provides a function to format the current Lua buffer using stylua.
--- @module plugins.QDtb.lua_format

local M = {}

--- Formats the current buffer using stylua-bin via npx.
--- Saves the file before running formatting.
--- @function format
M.format = function()
	if vim.bo.modifiable and vim.api.nvim_buf_get_name(0) ~= "" then
		vim.cmd("silent w")
		vim.notify("Saving file and running Formatting...", vim.log.levels.INFO)
	else
		vim.notify("Running Formatting...", vim.log.levels.INFO)
	end

	vim.system({ "npx", "@johnnymorganz/stylua-bin", vim.fn.expand("%:p") }, { text = true }, function(result)
		vim.schedule(function()
			if result.code ~= 0 then
				local error_message = result.stderr
				if not error_message or error_message == "" then
					error_message = "Unknown error during formatting execution."
				end
				vim.notify("Formatting failed:\n" .. error_message, vim.log.levels.ERROR)
			else
				if result.stderr and result.stderr ~= "" then
					vim.notify("Formatting ran with warnings:\n" .. result.stderr, vim.log.levels.WARN)
				else
					vim.notify("Formatting ran successfully!", vim.log.levels.INFO)
				end
				vim.cmd("e")
				vim.cmd("normal! zR")
			end
		end)
	end)
end

return M
