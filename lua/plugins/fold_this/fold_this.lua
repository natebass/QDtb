--- Fold_This Core Configuration.
--- Sets up custom folding text, fillchars, and buffer-local folding logic.
--- @module "plugins.fold_this.fold_this"
local M = {}
-- Default configuration allows users to override settings
local default_opts = {
	default_level = 99,
	enable_keymap = true, -- Automatically set up a toggle keymap
	pattern = "*", -- Apply to all filetypes by default
}

--- Custom function to render the fold text.
--- @function fold_text
--- @return string The formatted fold text.
function M.fold_text()
	local line = vim.fn.getline(vim.v.foldstart)
	local line_count = vim.v.foldend - vim.v.foldstart + 1
	return " 󰁂 " .. line .. " (" .. line_count .. " lines)"
end

--- Merges user options with defaults and sets up folding autocommands.
--- @function setup
--- @param user_opts table User-provided options to override defaults.
function M.setup(user_opts)
	-- Merge user options with defaults
	local opts = vim.tbl_deep_extend("force", default_opts, user_opts or {})

	-- Set global fold level start
	vim.o.foldlevelstart = opts.default_level

	-- Set fillchars globally
	vim.opt.fillchars:append({ fold = " " })

	local group = vim.api.nvim_create_augroup("CustomFolds", { clear = true })

	vim.api.nvim_create_autocmd("BufWinEnter", {
		group = group,
		pattern = opts.pattern,
		desc = "Apply custom folding settings",
		callback = function(args)
			local win = vim.api.nvim_get_current_win()
			local buf = args.buf

			-- Check for Tree-sitter
			local has_ts = false
			local ok, _ = pcall(vim.treesitter.get_parser, buf)
			if ok then
				has_ts = true
			end

			-- Window-local settings (vim.wo)
			if has_ts then
				vim.wo[win].foldmethod = "expr"
				if vim.treesitter.foldexpr then
					vim.wo[win].foldexpr = "v:lua.vim.treesitter.foldexpr()"
				else
					vim.wo[win].foldexpr = "nvim_treesitter#foldexpr()"
				end
			else
				vim.wo[win].foldmethod = "indent"
			end

			-- Point to this module for the fold text
			vim.wo[win].foldtext = [[v:lua.require('plugins.fold_this.fold_this').fold_text()]]
			vim.wo[win].foldenable = true

			-- Buffer-local keymap
			if opts.enable_keymap then
				vim.keymap.set("n", "<Tab>", "za", { buffer = buf, desc = "Toggle Fold" })
			end
		end,
	})
end

return M
