--- NPM Project Detection.
--- Detects if the current file is within an NPM project by locating package.json.
--- @module plugins.QDtb.package_json

-- Lua script for Neovim to detect if a file is within an NPM project.
-- Place this code in your Neovim configuration (e.g., ~/.config/nvim/lua/your_module/init.lua)
-- and then require it in your init.lua (e.g., require('your_module')).
local M = {}
--- Checks if a given directory contains a package.json file.
--- @param dir string The directory path to check.
--- @return boolean True if package.json is found, false otherwise.
local function has_package_json(dir)
	local package_json_path = dir .. "/package.json"
	local f = io.open(package_json_path, "r")
	if f then
		f:close()
		return true
	end
	return false
end
--- Finds the root of an NPM project by checking parent directories.
--- @param start_dir string The directory to start searching from.
--- @param max_depth number The maximum number of parent directories to check.
--- @return string|nil The path to the NPM project root, or nil if not found.
local function find_npm_project_root(start_dir, max_depth)
	local current_dir = vim.fn.fnamemodify(start_dir, ":p") -- Get absolute path
	for i = 1, max_depth do
		if has_package_json(current_dir) then
			return current_dir
		end
		local parent_dir = vim.fn.fnamemodify(current_dir .. "/..", ":p")
		if parent_dir == current_dir then -- Reached root directory (e.g., /)
			break
		end
		current_dir = parent_dir
	end
	return nil
end
--- Autocommand function to check for NPM project on file open.
--- @function check_npm_project
function M.check_npm_project()
	local file_path = vim.api.nvim_buf_get_name(0)
	if file_path == "" then
		return
	end -- No file name (e.g., new buffer)
	local current_dir = vim.fn.fnamemodify(file_path, ":h") -- Get directory of the current file
	local npm_root = find_npm_project_root(current_dir, 10) -- Check up to 10 directories back
	if npm_root then
		print(npm_root)
		print("NPM project detected at: " .. npm_root)
		-- You can add more actions here, for example:
		-- vim.g.npm_project_root = npm_root
		-- vim.cmd("cd" .. npm_root)
		-- vim.api.nvim_set_current_dir(npm_root)
	else
		print("Not inside an NPM project (or package.json not found within 10 parent dirs).")
	end
end

-- -- Define an autocommand group to manage our autocommands
-- vim.api.nvim_create_augroup("NpmProjectDetector", { clear = true })
--
-- -- Create an autocommand that runs on BufReadPost for common web file types
-- vim.api.nvim_create_autocmd("BufReadPost", {
--     group = "NpmProjectDetector",
--     pattern = {
--         "*.html", "*.htm", "*.css", "*.js", "*.jsx", "*.ts", "*.tsx", "*.json",
--         "*.vue", "*.svelte", "*.less", "*.scss", "*.sass",
--     },
--     callback = M.check_npm_project,
--     desc = "Check if the opened file is inside an NPM project",
-- })

return M
