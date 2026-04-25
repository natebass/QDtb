--- Initialization Module.
--- Loads packages, sets up plugins, and includes other configuration files.
--- @module config.init

-- ↓ -------- Learn -------- ↓ {{{
-- Lua ✏️
-- Ctrl+Down = } and for up
-- /var/lib/flatpak/exports/bin/dev.neovide.neovide
-- help lua-guide-mappings
-- put =expand('%:p')
-- w|source %
-- vim.opt.runtimepath:append('C:/Users/nateb/OneDrive/Documents/QDtb/Vim')
-- require('config')
-- ↑ ----------------------- ↑ }}}
-- Packages {{{
vim.pack.add({
	"https://github.com/mhinz/vim-startify",
	"https://github.com/vague2k/vague.nvim",
	"https://github.com/nvim-lua/plenary.nvim",
	"https://github.com/nvim-telescope/telescope.nvim",
	{ src = "https://codeberg.org/andyg/leap.nvim", name = "leap.nvim" },
	"https://github.com/preservim/nerdtree",
	"https://github.com/junegunn/goyo.vim",
	"https://github.com/junegunn/limelight.vim",
	"https://github.com/Mofiqul/vscode.nvim",
	"https://github.com/neovim/nvim-lspconfig",
	"https://github.com/nvim-focus/focus.nvim",
	"https://github.com/folke/zen-mode.nvim",
	"https://github.com/pocco81/true-zen.nvim",
	"https://github.com/github/copilot.vim",
	"https://github.com/wakatime/vim-wakatime",
})
-- }}}
-- Local plugins and configuration {{{
path_addition = vim.fn.expand(";/home/nwb/Documents/QDtb/lua/?.lua;/home/nwb/Documents/QDtb/lua/?/init.lua")
package.path = package.path .. path_addition
require("config.autocmds")
require("config.keymaps")
require("config.options")
require("config.other")
require("config.mini")
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
require("plugins.QDtb.colorscheme_cycler")
require("plugins.QDtb.package_json")
require("plugins.QDtb.autosave")
require("plugins.session_manager")
require("plugins.fold_this")
require("plugins.QDtb.window_title")
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
-- }}}
-- Footer
-- vim:foldmethod=marker:foldlevel=1:ft=vim
