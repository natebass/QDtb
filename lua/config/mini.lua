--- Mini.nvim Configuration.
--- Sets up various mini.* plugins for UI, editing, and utility enhancements.
--- @module config.mini
require("mini.icons").setup()
require("mini.notify").setup({
	window = { winblend = 25 },
})
vim.notify = require("mini.notify").make_notify()
require("mini.sessions").setup({ autoread = true, autowrite = true })
require("mini.align").setup()
require("mini.move").setup({
	mappings = {
		left = "<M-h>",
		right = "<M-l>",
		down = "<M-j>",
		up = "<M-k>",
		line_left = "<M-h>",
		line_right = "<M-l>",
		line_down = "<M-j>",
		line_up = "<M-k>",
	},
})
require("mini.extra").setup()
require("mini.misc").setup()
require("mini.bracketed").setup()
require("mini.bufremove").setup()
require("mini.diff").setup({
	view = { style = "sign", signs = { add = "+", change = "~", delete = "-" } },
})
require("mini.visits").setup()
require("mini.map").setup()
require("mini.git").setup()
require("mini.completion").setup({
	delay = { completion = 100, info = 300, signature = 50 },
})
require("mini.comment").setup()
require("mini.pick").setup({
	mappings = { choose_in_vsplit = "<C-CR>" },
})
require("mini.trailspace").setup()
require("mini.cursorword").setup()
require("mini.basics").setup({
	options = { basic = true, extra_ui = true, win_borders = "default" },
	mappings = { basic = true, option_toggle_prefix = [[\]], windows = true },
	autocommands = { basic = true, relnum_in_visual_mode = true },
})
require("mini.ai").setup({
	n_lines = 500,
})
require("mini.jump").setup()
require("mini.pairs").setup({
	mappings = {
		['"'] = false,
		["'"] = false,
	},
})
local miniclue = require("mini.clue")
miniclue.setup({
	triggers = {
		{ mode = "i", keys = "<C-x>" },
		{ mode = "n", keys = "g" },
		{ mode = "x", keys = "g" },
		{ mode = "n", keys = "'" },
		{ mode = "n", keys = "`" },
		{ mode = "x", keys = "'" },
		{ mode = "x", keys = "`" },
		{ mode = "i", keys = "<C-r>" },
		{ mode = "c", keys = "<C-r>" },
		{ mode = "n", keys = "<C-w>" },
		{ mode = "n", keys = "z" },
		{ mode = "x", keys = "z" },
		{ mode = "n", keys = "]" },
		{ mode = "n", keys = "[]" },
	},
	clues = {
		miniclue.gen_clues.builtin_completion(),
		miniclue.gen_clues.g(),
		miniclue.gen_clues.marks(),
		miniclue.gen_clues.registers(),
		miniclue.gen_clues.windows(),
		miniclue.gen_clues.z(),
	},
})
local gen_loader = require("mini.snippets").gen_loader
require("mini.snippets").setup({
	snippets = {
		gen_loader.from_lang(),
	},
})
local hipatterns = require("mini.hipatterns")
hipatterns.setup({
	highlighters = {
		fixme = { pattern = "%f[%w]()FIXME()%f[%W]", group = "MiniHipatternsFixme" },
		hack = { pattern = "%f[%w]()HACK()%f[%W]", group = "MiniHipatternsHack" },
		todo = { pattern = "%f[%w]()TODO()%f[%W]", group = "MiniHipatternsTodo" },
		note = { pattern = "%f[%w]()NOTE()%f[%W]", group = "MiniHipatternsNote" },
		hex_color = hipatterns.gen_highlighter.hex_color(),
	},
})
require("mini.surround").setup({
	mappings = {
		add = "xa",
		delete = "xd",
		find = "xf",
		find_left = "xF",
		highlight = "xh",
		replace = "xr",
	},
})
require("mini.files").setup({
	windows = { preview = true, width_focus = 30, width_preview = 50 },
	options = { use_as_default_explorer = true },
	mappings = {
		go_in = "L",
		go_in_plus = "l",
	},
	filter = function(fs_entry)
		local ignored_patterns = {
			"node_modules",
			".git",
			".svn",
			".hg",
			"__pycache__",
			"dist",
			"build",
			".next",
		}
		for _, pattern in ipairs(ignored_patterns) do
			if fs_entry.name == pattern then
				return true
			end
		end
		return false
	end,
})
require("mini.jump2d").setup({
	mappings = {
		start_jumping = "A",
	},
})
-- ── Other ─────────────────────────────────────────────────────────────
-- mini.doc, mini.fuzzy, mini.test are dev/authoring tools
-- only enable if you're building plugins
-- require('mini.doc').setup()
-- require('mini.fuzzy').setup()
-- require('mini.test').setup()
-- Footer
-- vim:foldmethod=marker:foldlevel=2
