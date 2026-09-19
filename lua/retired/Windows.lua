vim.opt.runtimepath:append("C:/Users/nateb/OneDrive/Documents/ADtb/Vim")
require("config")
local add, now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later
-- later(function()
-- 	add({ source = 'neovim/nvim-lspconfig' })
-- 	local lspconfig = require('lspconfig')
-- 	lspconfig.lua_ls.setup({
-- 		cmd = {
-- 			'C:/Users/nateb/Downloads/lua-language-server/bin/lua-language-server.exe',
-- 			'-E',
-- 			'C:/Users/nateb/Downloads/lua-language-server/main.lua',
-- 		},
-- 		settings = {
-- 			Lua = {
-- 				runtime = {
-- 					version = 'LuaJIT',
-- 					path = vim.split(package.path, ';'),
-- 				},
-- 				diagnostics = {
-- 					globals = { 'vim' },
-- 				},
-- 				workspace = {
-- 					library = vim.api.nvim_get_runtime_file('', true),
-- 					checkThirdParty = false,
-- 					preloadFileSize = 1000, -- optional: limit workspace scanning
-- 				},
-- 			},
-- 		},
-- 	})
-- 	vim.api.nvim_create_autocmd('LspAttach', {
-- 		group = vim.api.nvim_create_augroup('LspFormat', { clear = true }),
-- 		callback = function(args)
-- 			vim.api.nvim_create_autocmd('BufWritePre', {
-- 				buffer = args.buf,
-- 				callback = function()
-- 					vim.defer_fn(function()
-- 						vim.lsp.buf.format({ async = false, id = args.data.client_id })
-- 					end, 100)
-- 				end,
-- 			})
-- 		end,
-- 	})
-- end)
vim.g.startify_bookmarks = {
	{ w = "C:/Users/nateb/OneDrive/Documents/Adtb/Vim/Windows.lua" },
	{ r = "C:/Users/nateb/OneDrive/Documents/Adtb/Vim/lua/config.lua" },
	{ s = "C:/Users/nateb/OneDrive/Documents/Adtb/Vim/lua/plugins/session_manager/session_manager.lua" },
	{ f = "C:/Users/nateb/OneDrive/Documents/Adtb/Vim/lua/core/keymaps.lua" },
	{ W = "C:/Users/nateb/AppData/Local/nvim/init.lua" },
	{ l = "C:/Users/nateb/OneDrive/Documents/Adtb/IntelliJ/Windows IntelliJ.txt" },
	{ p = "C:/Users/nateb/OneDrive/Documents/PowerShell/Microsoft.Powershell_profile.ps1" },
}
vim.api.nvim_create_autocmd("VimEnter", {
	callback = function()
		if vim.fn.argc() == 0 then
			vim.cmd("cd C:/Users/nateb/OneDrive/Documents/ADtb/Vim")
		end
	end,
})
-- -- --- Custom Commands ---
-- -- Define custom commands that appear in Startify.
-- -- The key is the letter you'll press, the value is a table:
-- -- { { 'Display Name', 'Vim Command' }, { 'Another Name', 'Another Command' } }
-- vim.g.startify_commands = {
-- 	{
-- 		['e'] = { 'Edit Neovim Config', 'e ~/.config/nvim/init.lua' },
-- 		['s'] = { 'Source Config', 'source ~/.config/nvim/init.lua' },
-- 	},
-- 	{
-- 		['g'] = { 'Git Status', 'Gitsigns status_buffered' },
-- 		['f'] = { 'Find Files (Telescope)', 'Telescope find_files' },
-- 	},
-- }
-- vim.api.nvim_create_autocmd("VimEnter", {
-- 	callback = function()
-- 		vim.cmd("cd /Users/nateb/Source/Repos/app-capanel-web/")
-- 	end,
-- })
-- vim.g.startify_change_to_vcs_root = 1
-- vim.g.startify_change_to_dir = 0
-- vim.g.package_json_path = 'C:/Users/nateb/Source/Repos/be-gccpilot03-py/frontend/package.json'

-- Footer
-- vim:foldmethod=indent:foldlevel=3
