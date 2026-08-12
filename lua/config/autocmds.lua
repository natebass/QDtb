--- Autocommands Configuration.
--- Automated behaviors for filetype settings, formatting, etc..
--- @module config.autocmds

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

-- -- Autocmds are automatically loaded on the VeryLazy event
-- -- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- --
-- -- Add any additional autocmds here
-- -- with `vim.api.nvim_create_autocmd`
-- --
-- -- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- -- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")
--
-- vim.api.nvim_create_autocmd("FileType", {
--   pattern = "lua",
--   callback = function()
--     vim.opt_local.formatoptions:remove({ "r", "o" })
--   end,
--   desc = "Remove option to automatically add a comment for all files.",
-- })
-- vim.api.nvim_create_autocmd("User", {
--   pattern = "MiniFilesBufferCreate",
--   callback = function(args)
--     local map_buf = function(lhs, rhs)
--       vim.keymap.set("n", lhs, rhs, { buffer = args.data.buf_id })
--     end
--     map_buf("<Esc>", MiniFiles.close)
--   end,
--   desc = "Escape key closes the MiniFiles buffer.",
-- })
-- -- vim.api.nvim_create_autocmd("FileType", {
-- -- --   pattern = { "html", "json" },
-- -- --   callback = function()
-- -- --     vim.opt_local.foldmethod = "expr"
-- -- --     vim.opt_local.foldexpr = "v:lua.vim.treesitter.foldexpr()"
-- -- --     -- You can still set foldcolumn, foldlevel, etc., as desired
-- -- --   end,
-- -- -- })
-- -- vim.api.nvim_create_user_command("H", function(opts)
-- --    vim.cmd("help " .. opts.args)
-- --          vim.cmd("only")
-- --            end, { nargs = 1, complete = "help" })
-- Footer
-- vim:foldmethod=marker:foldlevel=1:ft=vim
