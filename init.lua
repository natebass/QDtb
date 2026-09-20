-- ↓ -------- Learn ✏️ -------- ↓ {{{
-- ↑ -------------------------- ↑ }}}
-- Load leaders before any plugins or custom filetype scripts.
vim.g.mapleader = vim.keycode("<space>")
vim.g.maplocalleader = "\\"
-- The single configuration entry point at lua/config/init.lua.
require("config")
-- Footer
-- vim:foldmethod=marker:foldlevel=1
