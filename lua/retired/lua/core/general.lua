local pj = require("../plugins.QDtb.package_json")
local colorscheme_cycler = require("../plugins.QDtb.colorscheme_cycler")
vim.cmd.colorscheme("default")
if type(colorscheme_cycler) == "table" and colorscheme_cycler.init_colorschemes then
	colorscheme_cycler.init_colorschemes()
else
	print("ERROR: colorscheme_cycler module not loaded correctly")
end
vim.keymap.set("n", "<leader>b", colorscheme_cycler.next_colorscheme, { desc = "Next Colorscheme" })
vim.keymap.set("n", "<leader>z", pj.check_npm_project, { desc = "Check if NPM project." })
-- vim.g.neovide_hide_mouse_when_typing = true

vim.api.nvim_create_autocmd("FileType", {
	pattern = "*",
	callback = function()
		vim.opt_local.formatoptions:remove({ "r", "o" })
	end,
	desc = "Remove option to automatically add a comment for all files.",
})
-- Format javascript on save.
-- vim.api.nvim_create_autocmd('BufWritePost', {
--     pattern = { '*.ts', '*.tsx', '*.js', '*.jsx', '*.mjs', '*.mts' }, -- Add more patterns as needed
--     callback = function()
--         vim.cmd([[silent !deno fmt ]] .. vim.fn.expand('%'))
--     end
-- })
-- ...existing code...
-- vim.api.nvim_create_autocmd('FileType', {
-- 	pattern = { 'html', 'json' },
-- 	callback = function()
-- 		vim.opt_local.foldmethod = 'expr'
-- 		vim.opt_local.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
-- 		-- You can still set foldcolumn, foldlevel, etc., as desired
-- 	end,
-- })
-- -- Autocmd to reload config on save
-- vim.api.nvim_create_autocmd('BufWritePost', {
-- 	pattern = '*.lua',
-- 	callback = function()
-- 		vim.notify('Reloading config...')
-- 		ReloadConfig()
-- 	end,
-- })
-- vim:foldmethod=marker:foldlevel=1
