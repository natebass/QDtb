-- Neovim colorscheme cycler utility
-- lua/my_utils/colorscheme_cycler.lua

local M = {}

M.colorschemes = {}
M.current_colorscheme_index = 0

-- Function to initialize the list of colorschemes
function M.init_colorschemes()
	-- Get all files in 'colors/' directories within 'runtimepath'
	local colors_path = vim.fn.globpath(vim.o.rtp, "colors/*.vim", 1, 1)

	-- Extract just the names (e.g., 'desert', 'molokai')
	M.colorschemes = vim.tbl_map(function(path)
		return vim.fn.fnamemodify(path, ":t:r")
	end, colors_path)

	-- Sort the list for consistent cycling
	table.sort(M.colorschemes)

	-- Find the index of the current colorscheme, if one is already set
	local current_scheme = vim.g.colors_name
	if current_scheme and current_scheme ~= "" then
		for i, scheme in ipairs(M.colorschemes) do
			if scheme == current_scheme then
				M.current_colorscheme_index = i
				break
			end
		end
	end

	if #M.colorschemes == 0 then
		vim.notify("No colorschemes found!", vim.log.levels.WARN)
	end
end

-- Function to apply the next colorscheme in the list
function M.next_colorscheme()
	-- Initialize colorschemes if not already done
	if #M.colorschemes == 0 then
		M.init_colorschemes()
		if #M.colorschemes == 0 then
			return -- No colorschemes to cycle through
		end
	end

	-- Increment index and wrap around
	M.current_colorscheme_index = M.current_colorscheme_index + 1
	if M.current_colorscheme_index > #M.colorschemes then
		M.current_colorscheme_index = 1
	end

	local scheme_to_set = M.colorschemes[M.current_colorscheme_index]

	-- Attempt to set the colorscheme
	pcall(vim.cmd.colorscheme, scheme_to_set)

	vim.notify("Set colorscheme: " .. scheme_to_set, vim.log.levels.INFO)
end

return M
