-- Local plugins and configuration {{{
-- neovim
require("plugins.QDtb.colorscheme_cycler")
require("plugins.QDtb.package_json")
require("plugins.QDtb.autosave")
require("plugins.QDtb.window_title")
require("plugins.code_style")
require("plugins.session_manager")
require("plugins.fold_this").setup({
	-- Options routed to fold_this.lua
	core = {
		default_level = 99,
		enable_keymap = true,
	},
	-- Options routed to fold_navigation.lua
	navigation = {
		enable_keymaps = true,
		next_key = "zj",
		prev_key = "zk",
		center_on_jump = true,
	},
})
require("telescope").setup({
	vimgrep_arguments = {
		"rg",
		"--color=never",
		"--no-heading",
		"--with-filename",
		"--line-number",
		"--column",
		"--smart-case",
		"--glob=!node_modules/**",
		"--glob=!.next/**",
		"--glob=!out/**",
	},

	file_ignore_patterns = {
		"node_modules/",
		"%.next/",
		"out/",
	},
})
-- }}}
-- Footer
-- vim:foldmethod=marker:foldlevel=1
