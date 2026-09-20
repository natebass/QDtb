--- General development configuration.
--- @module "config"
local M = {}
require("config.options")
if require("lib.utility").is_windows then
	require("config.windows")
else
	require("config.unix")
end
return M
