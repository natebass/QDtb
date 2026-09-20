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
