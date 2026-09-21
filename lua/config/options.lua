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
vim.o.colorcolumn = "+1"
vim.o.signcolumn = "yes"
vim.o.pumblend = 10
vim.o.pumheight = 10
vim.o.pumborder = "rounded"
vim.o.list = false
vim.o.listchars = "tab:  ,trail:-,nbsp:+"
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
vim.o.tabstop = 4
vim.o.softtabstop = 4
vim.o.shiftwidth = 4
vim.o.shiftround = true
vim.o.expandtab = false
vim.o.smartindent = true
vim.g.markdown_recommended_style = 0
-- }}}
-- Completion {{{
vim.o.autocomplete = true
vim.o.autocompletedelay = 100
vim.o.complete = "o,.^10,w^5,b^5"
vim.o.completeopt = "menu,menuone,noselect,popup,fuzzy"
-- }}}
-- Search {{{
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.inccommand = "nosplit"
vim.o.grepprg = "rg --vimgrep"
vim.o.grepformat = "%f:%l:%c:%m"
-- }}}
-- Files {{{
vim.o.undofile = true
vim.o.undolevels = 10000
vim.o.shada = "!,'1000,<50,s10,h,r/tmp/,r/private/"
vim.o.swapfile = false
vim.o.autowrite = true
-- }}}
vim.o.clipboard = vim.env.SSH_CONNECTION and "" or "unnamedplus"
-- }}}
-- Folds {{{
vim.o.foldmethod = "marker"
vim.o.foldlevel = 99
vim.o.foldtext = ""
-- }}}
-- Scroll & layout {{{
vim.o.scrolloff = 4
vim.o.sidescrolloff = 8
vim.o.smoothscroll = true
vim.o.linebreak = true
vim.o.wrap = false
vim.o.splitbelow = true
vim.o.splitright = true
vim.o.splitkeep = "screen"
vim.o.winminwidth = 5
vim.o.virtualedit = "block"
-- }}}
-- Miscellaneous {{{
vim.o.conceallevel = 2
vim.o.mouse = "a"
vim.o.spelllang = "en"
vim.o.jumpoptions = "view"
vim.o.wildmode = "longest:full,full"
vim.o.timeoutlen = 300
vim.o.updatetime = 200
vim.o.sessionoptions = "buffers,curdir,tabpages,winsize,help,globals,skiprtp,folds"
vim.o.shortmess = vim.o.shortmess .. "WIcC"
vim.o.termguicolors = true
-- }}}
if vim.g.neovide then
	vim.o.guifont = "ComicShannsMono Nerd Font Mono,Noto_Color_Emoji:h12"
	vim.o.linespace = 8
	vim.g.neovide_hide_mouse_when_typing = true
	vim.opt.guioptions:remove({ "m", "T", "r" })
	-- vim.print(vim.api.nvim_get_chan_info(vim.g.neovide_channel_id))
end
return M
-- Footer
-- vim:foldmethod=marker:foldlevel=0
