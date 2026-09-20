--- Lua LSP configuration
--- @module "plugins.code_style.lua"
local M = {}
vim.lsp.config("lua_ls", {
	settings = {
		Lua = {
			completion = {
				callSnippet = "Replace",
				-- 'complete' already scans buffers and windows for plain words, so lua_ls
				-- offering its own "Text" items only duplicates them in the same menu.
				showWord = "Disable",
			},
			-- Do NOT manually define workspace.library or diagnostics.globals here.
			-- lazydev handles that automatically now.
		},
	},
})
vim.lsp.enable("lua_ls")
return M
