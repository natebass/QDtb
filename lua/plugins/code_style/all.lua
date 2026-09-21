--- All code style autocommands.
--- @module "plugins.code_style.all"
local M = {}
vim.api.nvim_create_autocmd("FileType", {
	pattern = { "lua", "typescript", "typescriptreact", "javascript", "javascriptreact" },
	callback = function()
		vim.treesitter.start()
	end,
})
-- Format javascript on save.
-- vim.api.nvim_create_autocmd('BufWritePost', {
--     pattern = { '*.ts', '*.tsx', '*.js', '*.jsx', '*.mjs', '*.mts' }, -- Add more patterns as needed
--     callback = function()
--         vim.cmd([[silent !deno fmt ]] .. vim.fn.expand('%'))
--     end
-- })
vim.api.nvim_create_autocmd("FileType", {
	pattern = "*",
	callback = function()
		vim.opt_local.formatoptions:remove({ "r", "o" })
	end,
	desc = "Remove option to automatically add a comment for all files.",
})
-- vim.api.nvim_create_autocmd("FileType", {
-- 	pattern = { "html", "json" },
-- 	callback = function()
-- 		vim.opt_local.foldmethod = "expr"
-- 		vim.opt_local.foldexpr = "v:lua.vim.treesitter.foldexpr()"
-- 		-- You can still set foldcolumn, foldlevel, etc., as desired
-- 	end,
-- })
-- vim.api.nvim_create_user_command("H", function(opts)
-- 	vim.cmd("help " .. opts.args)
-- 	vim.cmd("only")
-- end, { nargs = 1, complete = "help" })
return M
-- Footer
-- vim:foldmethod=marker:foldlevel=1
