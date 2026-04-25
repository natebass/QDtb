--- Window Title Utility.
--- Sets the terminal window title based on the active Neovim buffer and project.
--- @module plugins.QDtb.window_title

local M = {}
--- Sets the terminal window title using xdotool.
--- Note: This assumes nvim is running in a terminal.
--- @function set_terminal_title
--- @param title string The title to set.
function M.set_terminal_title(title)
	-- Escape single quotes for shell command safety
	local escaped_title = title:gsub("'", "'\\''")
	local cmd = string.format("xdotool selectwindow getactivewindow set_window_title '%s'", escaped_title)
	-- Or using wmctrl:
	-- local cmd = string.format("wmctrl -F -r :ACTIVE: -T '%s'", escaped_title)
	-- Execute the command asynchronously to avoid blocking Neovim
	vim.fn.jobstart(cmd, {
		on_exit = function(job_id, data, event)
			if data ~= 0 then
				-- Handle error, e.g., print to messages
				-- print("Error setting window title: " .. data)
			end
		end,
		-- If you need stdout/stderr for debugging, you can capture it:
		-- stdout_callback = function(chan, data, event) print(table.concat(data)) end,
		-- stderr_callback = function(chan, data, event) print(table.concat(data)) end,
	})
end
--- Sets the title based on the current buffer/project.
--- Extracts the current buffer name and working directory name.
--- @function set_nvim_window_title
function M.set_nvim_window_title()
	-- Get current buffer name (if available)
	local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":t")
	-- Get current working directory name (project name)
	local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
	local title = ""
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
