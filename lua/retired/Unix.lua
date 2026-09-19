vim.opt.runtimepath:append("C:/Users/nateb/OneDrive/Documents/ADtb/Vim")
require("config")
local add, now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later
-- Check /home/nwb/Desktop/config/nvim/init.lua
vim.g.startify_bookmarks = {
	{ E = "/home/nwb/Source/Repos" },
	{ r = "/home/nwb/OneDrive/Documents/Adtb/Neovim.lua" },
	{ R = "/home/nwb/.config/nvim/init.lua" },
	{ T = "/home/nwb/.config/powershell/Microsoft.PowerShell_profile.ps1" },
	{ t = "/home/nwb/.config/nvim/init.lua" },
	{ W = "/home/nwb/OneDrive/Documents/Adtb/Snippets.json" },
	{ w = "/home/nwb/OneDrive/Documents/Adtb/Unix.lua" },
	{ d = "/home/nwb/.config/fish/config.fish" },
	{ x = "/home/nwb/Source/Repos/" },
	{ z = "/home/nwb/OneDrive/Documents/Emacs/Vim/Abbreviations.vim" },
}
vim.cmd([[
  autocmd! bufwritepost *nippets.json,*.vim,*.lua source /home/nwb/.config/nvim/init.lua
]])
if vim.g.neovide then
	-- vim.opt.guifont = 'Cascadia Code,Noto_Color_Emoji:h10'
	-- vim.opt.guifont = 'JetBrains Mono,Noto_Color_Emoji:h10'
	vim.opt.guifont = "ComicShannsMono Nerd Font Mono,Noto_Color_Emoji:h11"
	vim.opt.linespace = 8
	vim.g.neovide_hide_mouse_when_typing = true
	-- set guioptions-=m  ' menu bar
	-- set guioptions-=T  ' toolbar
	-- set guioptions-=r  ' scrollbar
	-- vim.print(vim.api.nvim_get_chan_info(vim.g.neovide_channel_id))
end
-- Footer
-- vim:foldmethod=marker:foldlevel=1:ft=vim
