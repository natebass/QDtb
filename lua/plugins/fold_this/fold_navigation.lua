--- Fold Navigation Utilities.
--- Provides functions to navigate between closed folds.
--- @module "plugins.fold_this.fold_navigation"
local M = {}
local default_opts = {
	enable_keymaps = true,
	next_key = "zj",
	prev_key = "zk",
	center_on_jump = true,
}
local opts = vim.deepcopy(default_opts)
--- Moves the cursor to the next or previous *closed* fold.
--- Steps with `zj`/`zk` until it lands inside a closed fold, and restores the
--- original view if there is no closed fold left in that direction.
--- `vim.cmd.normal` is used rather than `nvim_feedkeys`, because feedkeys only queues
--- the keys: the cursor would not have moved yet when the loop reads its position.
--- @param dir string Direction to search ('j' for down, 'k' for up).
function M.next_closed_fold(dir)
	local view = vim.fn.winsaveview()
	-- Always step at least once: starting inside a closed fold must still move on to
	-- the next one rather than reporting the fold the cursor is already in.
	while true do
		local before = vim.api.nvim_win_get_cursor(0)[1]
		vim.cmd.normal({ "z" .. dir, bang = true })
		local line = vim.api.nvim_win_get_cursor(0)[1]
		if line == before then
			-- No fold left in this direction: leave the view untouched.
			vim.fn.winrestview(view)
			return
		end
		if vim.fn.foldclosed(line) >= 0 then
			if opts.center_on_jump then
				vim.cmd.normal({ "zz", bang = true })
			end
			return
		end
	end
end
--- Applies navigation options and installs the fold-jumping keymaps.
--- @param user_opts table? User-provided options to override defaults.
function M.setup(user_opts)
	opts = vim.tbl_deep_extend("force", default_opts, user_opts or {})
	if not opts.enable_keymaps then
		return
	end
	vim.keymap.set("n", opts.next_key, function()
		M.next_closed_fold("j")
	end, { desc = "Fold: next closed fold" })
	vim.keymap.set("n", opts.prev_key, function()
		M.next_closed_fold("k")
	end, { desc = "Fold: previous closed fold" })
end
return M
