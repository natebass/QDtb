-- Repeat command function in Lua
local function RepeatCmd(cmd)
	local n = vim.v.count > 0 and vim.v.count or 1
	for _ = 1, n do
		vim.cmd(cmd)
	end
end

-- -- Reload function for all config modules
-- function ReloadConfig()
--  local modules = {
--    'lua.Neovim',
--    'lua.plugins.plugins_mini',
--    'lua.plugins.plugins_other',
--    'lua.core.all',
--    'lua.core.autocmd',
--    'lua.core.code_style',
--    'lua.core.keymaps',
--    'lua.core.options',
--    'lua.core.other',
--    'lua.plugins.QDtb.colorscheme_cycler',
--    'lua.plugins.QDtb.package_json',
--    'lua.plugins.QDtb.window_title',
--    'lua.plugins.QDtb.autosave',
--    'lua.plugins.session_manager.session_manager',
--  }
--  for _, mod in ipairs(modules) do
--    package.loaded[mod] = nil
--  end
--  local ok, keymaps = pcall(require, 'core.keymaps')
--  if ok and type(keymaps) == 'table' and keymaps.setup then
--    keymaps.setup()
--    vim.notify('Reloaded and reapplied keymaps.', vim.log.levels.INFO)
--  else
--    -- fallback: re-execute the file
--    dofile('C:/Users/nateb/OneDrive/Documents/ADtb/Vim/lua/core/keymaps.lua')
--    vim.notify('Reloaded keymaps by executing file.', vim.log.levels.INFO)
--  end
--  -- dofile('C:/Users/nateb/OneDrive/Documents/ADtb/Vim/Windows.lua')
-- end
