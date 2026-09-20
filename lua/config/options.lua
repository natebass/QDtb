--- Editor Options. Configures Neovim UI, editing behavior, search, and other core options.
--- @module "config.options"
local M = {}
-- UI {{{
vim.o.confirm = true
vim.o.number = false
vim.o.linespace = 4
vim.o.cmdheight = 0
vim.o.laststatus = 3
vim.o.winborder = "rounded"
vim.o.title = true
vim.o.ruler = false
vim.o.cursorline = true
vim.o.guicursor = "n-v-c-sm:hor10,i-ci-ve:ver25,r-cr-o:block"
vim.opt.colorcolumn = "+1"
vim.opt.signcolumn = "yes"
vim.opt.pumblend = 10
vim.opt.pumheight = 10
vim.opt.fillchars = {
	foldopen = "▾",
	foldclose = "▸",
	fold = " ",
	foldsep = " ",
	diff = "╱",
	eob = " ",
}
-- }}}
-- Editing {{{
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.shiftround = true
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.formatexpr = "v:lua.LazyVim.format.formatexpr()"
vim.g.markdown_recommended_style = 0
-- }}}
-- Search {{{
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.inccommand = "nosplit" -- Preview incremental substitute
vim.opt.grepprg = "rg --vimgrep"
vim.opt.grepformat = "%f:%l:%c:%m"
-- }}}
-- Files {{{
vim.opt.undofile = true
vim.opt.undolevels = 10000
vim.opt.swapfile = false
vim.opt.autowrite = true
vim.opt.confirm = true
-- }}}
-- Clipboard: skip in SSH so OSC 52 works automatically {{{
vim.opt.clipboard = vim.env.SSH_CONNECTION and "" or "unnamedplus"
-- }}}
-- Folds {{{
vim.opt.foldmethod = "marker"
vim.opt.foldlevel = 99
vim.opt.foldtext = ""
-- }}}
-- Scroll & layout {{{
vim.opt.scrolloff = 4
vim.opt.sidescrolloff = 8
vim.opt.smoothscroll = true
vim.opt.linebreak = true
vim.opt.wrap = false
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.splitkeep = "screen"
vim.opt.winminwidth = 5
vim.opt.virtualedit = "block" -- Allow cursor in blank space in visual block mode
-- }}}
-- Miscellaneous {{{
vim.opt.conceallevel = 2 -- Hide bold/italic markers but not substitutions
vim.opt.completeopt = "menu,menuone,noselect"
vim.opt.mouse = "a"
vim.opt.list = true -- Show invisible characters
vim.opt.spelllang = { "en" }
vim.opt.jumpoptions = "view"
vim.opt.wildmode = "longest:full,full"
vim.opt.timeoutlen = vim.g.vscode and 1000 or 300 -- Lower for faster which-key trigger
vim.opt.updatetime = 200 -- Trigger CursorHold sooner
vim.opt.sessionoptions = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp", "folds" }
vim.opt.shortmess:append({ W = true, I = true, c = true, C = true })
vim.opt.termguicolors = true
-- }}}
-- LazyVim {{{
vim.g.autoformat = true
vim.g.snacks_animate = true
vim.g.lazyvim_picker = "auto"
vim.g.lazyvim_cmp = "auto"
vim.g.ai_cmp = true -- Use AI source in completion engine over inline suggestions
vim.g.root_spec = { "lsp", { ".git", "lua" }, "cwd" }
vim.g.root_lsp_ignore = { "copilot" }
vim.g.deprecation_warnings = false
vim.g.trouble_lualine = true -- Show document symbol location in lualine
-- }}}

if vim.g.neovide then
	vim.o.guifont = "ComicShannsMono Nerd Font Mono,Noto_Color_Emoji:h12"
	vim.o.linespace = 8
	vim.g.neovide_hide_mouse_when_typing = true
	-- set guioptions-=m  ' menu bar
	-- set guioptions-=T  ' toolbar
	-- set guioptions-=r  ' scrollbar
	-- vim.print(vim.api.nvim_get_chan_info(vim.g.neovide_channel_id))
end
return M
-- Footer
-- vim:foldmethod=marker:foldlevel=0
