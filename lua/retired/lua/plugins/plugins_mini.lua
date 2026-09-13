local path_package = vim.fn.stdpath('data') .. '/site/'
local mini_path = path_package .. 'pack/deps/start/mini.nvim'
if not vim.loop.fs_stat(mini_path) then
	vim.cmd('echo "Installing `mini.nvim`" | redraw')
	local clone_cmd = {
		'git', 'clone', '--filter=blob:none',
		'https://github.com/echasnovski/mini.nvim', mini_path
	}
	vim.fn.system(clone_cmd)
	vim.cmd('packadd mini.nvim | helptags ALL')
	vim.cmd('echo "Installed `mini.nvim`" | redraw')
end
require('mini.deps').setup({ path = { package = path_package } })
local add, now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later
now(function() require('mini.icons').setup() end)
now(function()
	require('mini.notify').setup()
	vim.notify = require('mini.notify').make_notify()
end)
-- now(function() require('mini.statusline').setup() end)
-- now(function() require('mini.tabline').setup() end)
later(function() require('mini.sessions').setup({ autoread = true, autowrite = true }) end)
later(function() require('mini.align').setup() end)
later(function() require('mini.move').setup() end)
later(function() require('mini.extra').setup() end)
later(function() require('mini.misc').setup() end)
later(function() require('mini.bracketed').setup() end)
later(function() require('mini.bufremove').setup() end)
later(function() require('mini.diff').setup() end)
later(function() require('mini.visits').setup() end)
later(function() require('mini.map').setup() end)
later(function() require('mini.git').setup() end)
later(function() require('mini.completion').setup() end)
later(function() require('mini.comment').setup() end)
later(function() require('mini.pick').setup() end)
later(function() require('mini.trailspace').setup() end)
later(function() require('mini.cursorword').setup() end)
later(function() require('mini.basics').setup() end)
later(function()
	require('mini.pairs').setup({
		mappings = {
			['"'] = false,
			["'"] = false,
		},
	})
end)
later(function() require('mini.ai').setup() end)
later(function()
	local miniclue = require('mini.clue')
	miniclue.setup({
		triggers = {
			-- Leader triggers
			{ mode = 'n', keys = '<Leader>' },
			{ mode = 'x', keys = '<Leader>' },
			-- Built-in completion
			{ mode = 'i', keys = '<C-x>' },
			-- `g` key
			{ mode = 'n', keys = 'g' },
			{ mode = 'x', keys = 'g' },
			-- Marks
			{ mode = 'n', keys = "'" },
			{ mode = 'n', keys = '`' },
			{ mode = 'x', keys = "'" },
			{ mode = 'x', keys = '`' },
			-- Registers
			{ mode = 'n', keys = "'" },
			{ mode = 'x', keys = "'" },
			{ mode = 'i', keys = '<C-r>' },
			{ mode = 'c', keys = '<C-r>' },
			-- Window commands
			{ mode = 'n', keys = '<C-w>' },
			-- `z` key
			{ mode = 'n', keys = 'z' },
			{ mode = 'x', keys = 'z' },
			-- Other
			{ mode = 'n', keys = ']' },
			{ mode = 'n', keys = '[]' },
		},
		clues = {
			-- Enhance this by adding descriptions for <Leader> mapping groups
			miniclue.gen_clues.builtin_completion(),
			miniclue.gen_clues.g(),
			miniclue.gen_clues.marks(),
			miniclue.gen_clues.registers(),
			miniclue.gen_clues.windows(),
			miniclue.gen_clues.z(),
		},
	})
end)
later(function()
	local gen_loader = require('mini.snippets').gen_loader
	require('mini.snippets').setup({
		snippets = {
			-- Load custom file with global snippets first (adjust for Windows)
			-- gen_loader.from_file('~/.config/nvim/snippets/global.json'),
			-- Load snippets based on current language by reading files from
			-- 'snippets/' subdirectories from 'runtimepath' directories.
			gen_loader.from_lang(),
		},
	})
end)
later(function()
	local hipatterns = require('mini.hipatterns')
	require('mini.hipatterns').setup({
		highlighters = {
			fixme = { pattern = '%f[%w]()FIXME()%f[%W]', group = 'MiniHipatternsFixme' },
			hack = { pattern = '%f[%w]()HACK()%f[%W]', group = 'MiniHipatternsHack' },
			todo = { pattern = '%f[%w]()TODO()%f[%W]', group = 'MiniHipatternsTodo' },
			note = { pattern = '%f[%w]()NOTE()%f[%W]', group = 'MiniHipatternsNote' },
			hex_color = hipatterns.gen_highlighter.hex_color(),
		},
	})
end)
later(function()
	require('mini.surround').setup({
		mappings = {
			add = 'xa',
			delete = 'xd',
			find = 'xf',
			find_left = 'xF',
			highlight = 'xh',
			replace = 'xr',
		},
	})
end)
later(function()
	require('mini.files').setup({
		mappings = {
			go_in = 'L',
			go_in_plus = 'l',
		},
		-- Path to be shown and used as root. Can be string or a function.
		-- Default: `vim.fn.getcwd()`
		-- root = nil,
		-- Whether to show hidden files. Default: `false`.
		-- show_hidden = nil,
		-- Table of patterns to be ignored. Default: `{ '.git', '.DS_Store', 'Thumbs.db' }`
		filter = function(fs_entry)
			-- `fs_entry` is a table containing information about the file system entry.
			-- `fs_entry.path` is the full path.
			-- `fs_entry.name` is the base name.
			-- `fs_entry.is_dir` is a boolean.
			-- Common patterns to ignore
			local ignored_patterns = {
				'node_modules',
				'.git',
				'.svn',
				'.hg',
				'__pycache__',
				'dist',
				'build',
				'.next',
			}
			for _, pattern in ipairs(ignored_patterns) do
				-- Check if the name or path contains the pattern.
				-- For directories, it's usually enough to check the name.
				if fs_entry.name == pattern then
					return true -- true means ignore
				end
				-- For more complex path-based ignoring, you might use string.find or vim.fn.match
				-- if fs_entry.is_dir and string.find(fs_entry.path, '/' .. pattern .. '/') then
				--   return true
				-- end
			end
			return false -- false means do not ignore
		end,
	})
end)
later(function()
	require('mini.jump').setup()
end)
later(function()
	require('mini.jump2d').setup({
		mappings = {
			start_jumping = 'A',
		},
	})
end)

vim.api.nvim_create_autocmd('User', {
	pattern = 'MiniFilesBufferCreate',
	callback = function(args)
		local map_buf = function(lhs, rhs)
			vim.keymap.set('n', lhs, rhs, { buffer = args.data.buf_id })
		end
		map_buf('<Esc>', MiniFiles.close)
	end,
	desc = 'Escape key closes the MiniFiles buffer.',
})