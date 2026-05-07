-- Create a user command :HelloPlugin
-- vim.api.nvim_create_user_command("HelloPlugin", function()
--     require("plugins/my_plugin").say_hello()
-- end, {})

require("lazydev").setup({
	library = {
		-- Load luvit types when the `vim.uv` word is found
		{ path = "luvit-meta/library", words = { "vim%.uv" } },
		-- Load Snacks types if you use it
		{ path = "snacks.nvim", words = { "Snacks" } },
	},
})
