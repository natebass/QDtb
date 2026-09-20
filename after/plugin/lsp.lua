--- LSP support plugins.
--- lua_ls itself is configured in lua/plugins/code_style/lua.lua; nvim-lspconfig
--- only needs to be on the runtimepath (vim.pack does that with `load = false`)
--- for vim.lsp.enable() to pick up its lsp/lua_ls.lua definition.
--- @module "config.lsp"

vim.cmd.packadd("lazydev.nvim")

require("lazydev").setup({
	library = {
		-- Load the luv type definitions that ship with lua-language-server when
		-- the `vim.uv` word is found. This replaces the archived luvit-meta plugin.
		{ path = "${3rd}/luv/library", words = { "vim%.uv" } },
	},
})

--- 'autocomplete' (see lua/config/options.lua) drives the popup and already reaches the
--- server through the "o" flag in 'complete', so autotrigger stays off: it would be a
--- second, redundant trigger. Enabling the module is still required for everything that
--- happens *around* the menu -- resolving documentation into the "popup" window, and
--- applying an item's side effects on <C-y>: snippet expansion (lua_ls sends snippets
--- because of callSnippet = "Replace"), additional text edits such as auto-imports, and
--- any command the server attaches to the item.
vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(args)
		vim.lsp.completion.enable(true, args.data.client_id, args.buf)
	end,
	desc = "Route LSP completion through the built-in popup menu",
})

-- NOTE: automatic signature help.
-- mini.completion used to open the signature float on its own after 50ms. Neovim 0.12 has
-- no option for that: the only built-in entry point is the default <C-s> mapping in Insert
-- mode (|i_CTRL-S|), which has to be pressed. Uncommenting the block below brings the old
-- behaviour back. It hooks the characters the server itself nominates as signature
-- triggers -- lua_ls reports { "(", "," } -- and opens the same float <C-s> would.
-- `focus = false` keeps the cursor in the buffer, and vim.schedule defers to after the
-- character is actually inserted, because InsertCharPre fires beforehand and the server
-- would otherwise resolve the position one column short. Verified against lua_ls 3.19.0.
-- vim.api.nvim_create_autocmd("LspAttach", {
-- 	callback = function(args)
-- 		local client = vim.lsp.get_client_by_id(args.data.client_id)
-- 		local triggers = client
-- 			and client.server_capabilities.signatureHelpProvider
-- 			and client.server_capabilities.signatureHelpProvider.triggerCharacters
-- 		if not triggers or #triggers == 0 then
-- 			return
-- 		end
-- 		vim.api.nvim_create_autocmd("InsertCharPre", {
-- 			buffer = args.buf,
-- 			callback = function()
-- 				if vim.list_contains(triggers, vim.v.char) then
-- 					vim.schedule(function()
-- 						vim.lsp.buf.signature_help({ focus = false, silent = true })
-- 					end)
-- 				end
-- 			end,
-- 			desc = "Open signature help on the server's trigger characters",
-- 		})
-- 	end,
-- 	desc = "Automatic signature help, mini.completion style",
-- })
