vim.lsp.config("lua_ls", {
	settings = {
		Lua = {
			completion = {
				callSnippet = "Replace",
			},
			-- Do NOT manually define workspace.library or diagnostics.globals here.
			-- lazydev handles that automatically now.
		},
	},
})
vim.lsp.enable("lua_ls")
