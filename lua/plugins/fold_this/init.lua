--- Fold_This Initialization.
--- Provides a unified setup function for fold_this core logic and navigation.
--- @module "plugins.fold_this.init"
local M = {}
-- Load both of your internal modules
local fold_core = require("plugins.fold_this.fold_this")
local fold_nav = require("plugins.fold_this.fold_navigation")
-- (Optional but recommended) Expose the navigation functions on the main
-- module so users can call `require("plugins.fold_this").next_closed_fold('j')` manually
M.next_closed_fold = fold_nav.next_closed_fold
--- Configures both fold core and fold navigation components.
--- @function setup
--- @param user_opts table Optional user configuration.
function M.setup(user_opts)
	user_opts = user_opts or {}
	-- We split the options into categories so the user's config is organized.
	-- If they don't provide options for a specific section, pass an empty table.
	local core_opts = user_opts.core or {}
	local nav_opts = user_opts.navigation or {}
	-- 1. Setup the core folding logic (your original fold_this.lua)
	if type(fold_core.setup) == "function" then
		fold_core.setup(core_opts)
	end
	-- 2. Setup the navigation and keymaps (the newly upgraded fold_navigation.lua)
	if type(fold_nav.setup) == "function" then
		fold_nav.setup(nav_opts)
	end
end

return M
