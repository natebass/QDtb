--- Autosave Configuration.
--- Automatically saves files when focus is lost or before exiting Vim.
--- @module plugins.QDtb.autosave

local augroup = vim.api.nvim_create_augroup("QdtbAutosave", { clear = true })
-- This list covers common web development files and general programming files.
local filetypes_to_save = {
	"html",
	"htm",
	"css",
	"scss",
	"less",
	"js",
	"jsx",
	"ts",
	"tsx",
	"json",
	"jsonc",
	"vue",
	"svelte",
	"astro",
	"php",
	"py",
	"rb",
	"go",
	"java",
	"c",
	"cpp",
	"h",
	"hpp",
	"cs",
	"rs",
	"toml",
	"yaml",
	"yml",
	"xml",
	"md",
	"txt",
	"sh",
	"bash",
	"zsh",
	"fish",
	"conf",
	"ini",
	"log",
	"sql",
	"dockerfile",
	"gitignore",
	"gitconfig",
	"editorconfig",
	"prettierrc",
	"eslintrc",
	"webmanifest",
	"svg",
	"csv",
	"tsv",
	"diff",
	"patch",
	"graphql",
	"proto",
	"zig",
	"rust",
	"swift",
	"kt",
	"dart",
	"elm",
	"erlang",
	"fsharp",
	"haskell",
	"nim",
	"ocaml",
	"perl",
	"r",
	"scala",
	"solidity",
	"stylus",
	"twig",
	"liquid",
	"pug",
	"haml",
	"slim",
	"markdown",
	"asciidoc",
	"rst",
	"org",
	"nix",
	"cmake",
	"make",
	"glsl",
	"wgsl",
	"wgsl",
	"hlsl",
	"metal",
	"cuda",
	"ps1",
	"bat",
	"cmd",
	"vbs",
	"psd1",
	"psm1",
	"clj",
	"cljs",
	"edn",
	"lisp",
	"scm",
	"ss",
	"d",
	"pas",
	"ada",
	"cobol",
	"fortran",
	"matlab",
	"rkt",
	"sml",
	"tcl",
	"vhdl",
	"verilog",
	"systemverilog",
	"awk",
	"sed",
	"expect",
	"tcl",
	"awk",
	"sed",
	"jsp",
	"asp",
	"aspx",
	"ejs",
	"hbs",
	"handlebars",
	"typescriptreact",
}
-- Create the autocmd for FocusLost and VimLeavePre events
vim.api.nvim_create_autocmd({ "FocusLost", "VimLeavePre" }, {
	group = augroup,
	callback = function(args) -- The callback receives an 'args' table
		local bufnr = vim.api.nvim_get_current_buf()
		local filetype = vim.bo[bufnr].filetype
		local modified = vim.bo[bufnr].modified
		local bufname = vim.api.nvim_buf_get_name(bufnr)
		-- Determine which event triggered the autocmd
		local event_name = args.event or "UnknownEvent"
		-- vim.notify(
		-- 	'Autocmd triggered: ' .. event_name .. ' for ' .. (bufname == '' and '[No Name]' or bufname),
		-- 	vim.log.levels.INFO
		-- )
		-- Check if the buffer is modified and its filetype is in our list

		if modified and vim.tbl_contains(filetypes_to_save, filetype) then
			-- Check if the buffer has a name (i.e., it's a file, not a scratch buffer)
			if bufname and bufname ~= "" then
				-- Save the buffer
				vim.cmd("silent! wa")
				-- vim.notify('Autosaved: ' .. bufname, vim.log.levels.INFO)
			else
				vim.notify("Not saving untitled buffer on " .. event_name, vim.log.levels.DEBUG)
			end
		else
			vim.notify(
				"Not saving "
					.. (bufname == "" and "[No Name]" or bufname)
					.. " (modified: "
					.. tostring(modified)
					.. ", filetype: "
					.. filetype
					.. ") on "
					.. event_name,
				vim.log.levels.DEBUG
			)
		end
	end,
})

vim.api.nvim_create_autocmd("FileType", {
	pattern = { "lua", "typescript", "tsx", "ts", "tsx", "javascript", "js" },
	callback = function()
		vim.treesitter.start()
	end,
})
-- Optional: Add a message when the autosave module is loaded
-- vim.notify('Qdtb autosave module loaded.', vim.log.levels.INFO)
