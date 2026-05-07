--- This is the main entry point. Check the auto loaded folders for other configurations.
-- ↓ -------- Learn -------- ↓ {{{
-- Lua ✏️
-- Ctrl+Down = } and for up
-- /var/lib/flatpak/exports/bin/dev.neovide.neovide
-- help lua-guide-mappings
-- put =expand("%:p")
-- w|source %
-- vim.opt.runtimepath:append("C:/Users/nateb/OneDrive/Documents/QDtb/Vim")
-- path_addition = vim.fn.expand(";/home/nwb/Documents/QDtb/lua/?.lua;/home/nwb/Documents/QDtb/lua/?/init.lua")
-- package.path = package.path .. path_addition
-- ↑ ----------------------- ↑ }}}
vim.cmd("colorscheme nordstone")
-- The leader key needs to be set before lazy.nvim.
vim.g.mapleader = vim.keycode("<space>")
vim.g.maplocalleader = "\\"
-- vim.g.maplocalleader = vim.keycode(",")
require("config")
-- Footer
-- vim:foldmethod=marker:foldlevel=1
