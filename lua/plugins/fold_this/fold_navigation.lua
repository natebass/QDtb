--- Fold Navigation Utilities.
--- Provides functions to navigate between closed folds.
--- @module "plugins.fold_this.fold_navigation"
local M = {}
--- Moves the cursor to the next or previous closed fold.
--- @function next_closed_fold
--- @param dir string Direction to search ('j' for down, 'k' for up).
function M.next_closed_fold(dir)
	local cmd = "z" .. dir
	local view = vim.fn.winsaveview()
	local l0 = 0
	local l = view.lnum
	local open = true
	while l ~= l0 and open do
		vim.api.nvim_feedkeys(cmd, "n", true)
		l0 = l
		l = vim.api.nvim_win_get_cursor(0)[1]
		open = vim.fn.foldclosed(l) < 0
	end
	if open then
		vim.fn.winrestview(view)
	end
end

-- vim.cmd [[
--   function! NextClosedFold(dir)
--     let cmd = 'norm!z'..a:dir
--     let view = winsaveview()
--     let [l0, l, open] = [0, view.lnum, 1]
--     while l != l0 && open
--         exe cmd
--         let [l0, l] = [l, line('.')]
--         let open = foldclosed(l) < 0
--     endwhile
--     if open
--         call winrestview(view)
--     endif
--   endfunction
-- ]]
return M
