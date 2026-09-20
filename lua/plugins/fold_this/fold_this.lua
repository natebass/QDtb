--- Fold_This Core Configuration.
--- Sets up custom folding text, fillchars, and buffer-local folding logic.
--- Caveats:
--- init.lua calls fold_nav.setup only if it exists. I didn't check whether the navigation module defines one. Going by the diff, it appears to have no setup, so navigation options and keymaps are effectively unused.
-- <Tab> → za overrides <Tab> for jumplist navigation (<C-i>) in normal mode. This is on by default.
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

--- Applies the default (treesitter, else indent) folding to a window.
--- @param win integer
--- @param buf integer
function M.apply_default(win, buf)
	if pcall(vim.treesitter.get_parser, buf) then
		vim.wo[win].foldmethod = "expr"
		vim.wo[win].foldexpr = "v:lua.vim.treesitter.foldexpr()"
	else
		vim.wo[win].foldmethod = "indent"
	end
	vim.wo[win].foldtext = [[v:lua.require('plugins.fold_this.fold_this').fold_text()]]
	vim.wo[win].foldenable = true
end

--- Switches the current window to marker folding, optionally closing all folds.
--- @param close_all boolean
function M.set_marker(close_all)
	local win = vim.api.nvim_get_current_win()
	vim.w[win].fold_this_marker = true
	vim.wo[win].foldmethod = "marker"
	vim.wo[win].foldenable = true
	if close_all then
		vim.cmd("normal! zM")
	end
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
	-- Set fillchars to remove the vertical line guide for folds.
	-- This creates a cleaner, less cluttered look.
	-- vim.o.fillchars = 'fold: '

	-- Create a dedicated autocommand group to ensure our settings don't
	-- conflict with other plugins.
	local group = vim.api.nvim_create_augroup("CustomFolds", { clear = true })

	-- Create an autocommand that runs whenever a buffer is entered into a window.
	-- This applies our folding settings on a per-window basis.
	vim.api.nvim_create_autocmd("BufWinEnter", {
		group = group,
		pattern = opts.pattern,
		desc = "Apply custom folding settings",
		callback = function(args)
			local win = vim.api.nvim_get_current_win()
			-- Respect a window the user switched to marker folding.
			if not vim.w[win].fold_this_marker then
				M.apply_default(win, args.buf)
			end

			-- Buffer-local keymap
			if opts.enable_keymap then
				vim.keymap.set("n", "<Tab>", "za", { buffer = args.buf, desc = "Toggle Fold" })
			end
		end,
	})

	-- vim.notify('fold-plug: Custom folding enabled.', vim.log.levels.INFO)
end

return M
