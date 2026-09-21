--- Window Title Utility.
--- Sets the terminal window title based on the active Neovim buffer and project.
--- Note: 'title' already makes Neovim set the title through the terminal/GUI itself.
--- This module is only needed for window managers that ignore that, and it requires xdotool.
--- @module "plugins.QDtb.window_title"
local M = {}
--- Sets the terminal window title using xdotool.
--- The title is passed as an argv element, so no shell quoting is involved.
--- @param title string The title to set.
function M.set_terminal_title(title)
	if vim.fn.executable("xdotool") ~= 1 then
		return
	end
	vim.system({ "xdotool", "getactivewindow", "set_window_title", title }, { text = true }, function(result)
		if result.code ~= 0 then
			local message = result.stderr ~= "" and result.stderr or ("exit code " .. result.code)
			vim.schedule(function()
				vim.notify("Could not set the window title: " .. message, vim.log.levels.DEBUG)
			end)
		end
	end)
end
--- Sets the title based on the current buffer/project.
--- Extracts the current buffer name and working directory name.
function M.set_nvim_window_title()
	local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":t")
	local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
	local title
	if filename ~= "" then
		title = string.format("%s - %s", filename, project_name)
	else
		title = project_name
	end
	if title == "" then
		title = "A Dios te bendiga" -- Default title
	end
	M.set_terminal_title(title)
end
return M
