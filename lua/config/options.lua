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
-- Matches 'winborder' above so the completion menu is framed like every other float.
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
-- Neovim 0.12 completes as you type on its own (|ins-autocompletion|), which is why
-- mini.completion is no longer set up in after/plugin/mini.lua.
vim.o.autocomplete = true
-- mini.completion waited 100ms before opening its popup. The native default is 0, which
-- pops the menu between keystrokes mid-word, so keep the old feel.
vim.o.autocompletedelay = 100
-- Sources for both <C-n> and the automatic menu. "o" is 'omnifunc', which LSP points at
-- vim.lsp.omnifunc() on attach; it goes first because sources earlier in the list get a
-- larger slice of the decaying timeout. The keyword sources are capped with "^{n}" so a
-- common word cannot crowd the language server out of the menu. Dropped from the default
-- ".,w,b,u,t": "u" (unloaded buffers, the slowest scan) and "t" (nothing here writes tags).
vim.o.complete = "o,.^10,w^5,b^5"
-- "popup" is the native replacement for mini.completion's info window; it needs
-- vim.lsp.completion.enable() (see after/plugin/lsp.lua) to resolve the documentation.
-- "menu,menuone" are kept for the manual <C-x> completions, which suspend autocompletion.
-- "noselect" is listed even though :h 'completeopt' says 'autocomplete' implies it: on
-- 0.12.5 that only holds for the keyword sources. Completing through 'omnifunc' preselects
-- item 0 and writes it into the buffer mid-word, so the flag has to be spelled out.
vim.o.completeopt = "menu,menuone,noselect,popup,fuzzy"
-- }}}
-- Search {{{
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.inccommand = "nosplit" -- Preview incremental substitute
vim.o.grepprg = "rg --vimgrep"
vim.o.grepformat = "%f:%l:%c:%m"
-- }}}
-- Files {{{
vim.o.undofile = true
vim.o.undolevels = 10000
vim.o.swapfile = false
vim.o.autowrite = true
-- }}}
-- Clipboard: skip in SSH so OSC 52 works automatically {{{
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
vim.o.virtualedit = "block" -- Allow cursor in blank space in visual block mode
-- }}}
-- Miscellaneous {{{
vim.o.conceallevel = 2 -- Hide bold/italic markers but not substitutions
vim.o.mouse = "a"
vim.o.spelllang = "en"
vim.o.jumpoptions = "view"
vim.o.wildmode = "longest:full,full"
vim.o.timeoutlen = 300 -- Lower for faster which-key trigger
vim.o.updatetime = 200 -- Trigger CursorHold sooner
vim.o.sessionoptions = "buffers,curdir,tabpages,winsize,help,globals,skiprtp,folds"
vim.o.shortmess = vim.o.shortmess .. "WIcC"
vim.o.termguicolors = true
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
