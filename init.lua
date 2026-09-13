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
-- dofile("C:/Users/nateb/OneDrive/Documents/ADtb/Vim/Windows.lua")
-- when you explicitly need to re-run a script dynamically on demand or execute a Lua file sitting in a non-standard location outside of your Neovim runtimepath
-- ↑ ----------------------- ↑ }}}
-- Load leaders before any plugins or custom filetype scripts.
vim.g.mapleader = vim.keycode("<space>")
vim.g.maplocalleader = "\\"
require("config")
-- Footer
-- vim:foldmethod=marker:foldlevel=1
