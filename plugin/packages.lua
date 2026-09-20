--- Add packages with the native Neovim package manager.

vim.pack.add({
	"https://github.com/echasnovski/mini.nvim",
}, { load = true })
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
	"https://github.com/folke/lazydev.nvim",
	"https://github.com/Bilal2453/luvit-meta",
	"https://github.com/folke/snacks.nvim",
}, { load = false })

local command_packages = {}

--- Map every command a package defines to the package that defines it.
local function map_commands(package, commands)
	for _, command in ipairs(commands) do
		command_packages[command] = package
	end
end

map_commands("goyo.vim", { "Goyo" })
map_commands("limelight.vim", { "Limelight" })
map_commands("nerdtree", {
	"NERDTree",
	"NERDTreeClose",
	"NERDTreeCWD",
	"NERDTreeExplore",
	"NERDTreeFind",
	"NERDTreeFocus",
	"NERDTreeFromBookmark",
	"NERDTreeMirror",
	"NERDTreeRefreshRoot",
	"NERDTreeToggle",
	"NERDTreeToggleVCS",
	"NERDTreeVCS",
})
map_commands("true-zen.nvim", { "TZAtaraxis", "TZFocus", "TZMinimalist", "TZNarrow" })
map_commands("vim-startify", { "SClose", "SDelete", "SLoad", "SSave", "Startify", "StartifyDebug" })

vim.api.nvim_create_autocmd("CmdUndefined", {
	pattern = vim.tbl_keys(command_packages),
	callback = function(args)
		vim.cmd.packadd(command_packages[args.match])
	end,
	desc = "Load optional native packages when one of their commands is used",
})

vim.api.nvim_create_autocmd("InsertEnter", {
	once = true,
	callback = function()
		vim.cmd.packadd("copilot.vim")
	end,
	desc = "Load Copilot when entering Insert mode",
})

vim.api.nvim_create_autocmd("VimEnter", {
	once = true,
	callback = function()
		vim.schedule(function()
			vim.cmd.packadd("vim-wakatime")
		end)
	end,
	desc = "Start WakaTime after the first UI frame",
})
