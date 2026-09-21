--- Keymaps Configuration.
--- Sets up global, leader, and plugin-specific keybindings.
--- @module "config.keymaps"

local map = vim.keymap.set
-- Special {{{
-- Package JSON Check
local pj = require("plugins.QDtb.package_json")
map("n", "<leader>z", pj.check_npm_project, { desc = "Check if NPM project." })
-- Focus & Leap
require("focus").setup()
map({ "n", "x", "o" }, "S", "<plug>(leap-backward)")
map({ "n", "x", "o" }, "gs", "<plug>(leap-from-window)")
map({ "n", "x", "o" }, "gS", "<plug>(leap)")
-- }}}
-- User Leader Mappings {{{
map("n", "<leader>A", "")
map("n", "<leader>a", "<cmd>silent !npx prettier --write % &<CR>", { silent = true })
map("n", "<leader>B", "<cmd>Telescope buffers<CR>", { silent = true })
map("n", "<leader>bh", "<cmd>bprevious<cr>", { desc = "Prev Buffer" })
map("n", "<leader>bl", "<cmd>bnext<cr>", { desc = "Next Buffer" })
map("n", "[b", "<cmd>bprevious<cr>", { desc = "Prev Buffer" })
map("n", "]b", "<cmd>bnext<cr>", { desc = "Next Buffer" })
map("n", "<leader>bb", "<cmd>e #<cr>", { desc = "Switch to Other Buffer" })
map("n", "<leader>`", "<cmd>e #<cr>", { desc = "Switch to Other Buffer" })
map("n", "<leader>bD", "<cmd>:bd<cr>", { desc = "Delete Buffer and Window" })
map("n", "<leader>C", "<cmd>Telescope help_tags<CR>", { silent = true })
map("n", "<leader>D", "<cmd>Telescope colorscheme<CR>", { silent = true })
map("n", "<leader>d", "<cmd>restart<CR>")
map("n", "<leader>E", "<cmd>lua MiniPick.builtin.files()<CR>")
map("n", "<leader>e", "<cmd>lua MiniPick.builtin.grep()<CR>")
map("n", "<leader>F", "<cmd>restart<cr>")
map("n", "<leader>f", "<cmd><up><cr>")
map("n", "<leader>G", "<cmd>lua MiniPick.builtin.cli()<CR>")
map("n", "<leader>g", "<cmd>set wrap<cr><cmd>Goyo<cr>")
map("n", "<leader>H", "<cmd>lua MiniPick.builtin.help()<CR>", { desc = "MiniPick Help" })
map("n", "<leader>h", "<cmd>set nowrap<cr>:Goyo<cr>", { silent = true })
map("n", "<leader>I", "")
map("n", "<leader>i", "<cmd>Limelight!!<cr>", { silent = true })
map("n", "<leader>J", ":<c-p><cr>")
map("n", "<leader>j", ":<c-p>")
map("n", "<leader>K", "/<c-f>")
map("n", "<leader>k", "/<up>")
map("n", "<leader>L", "<cmd>lua MiniPick.builtin.grep_live()<CR>")
map("n", "<leader>l", "<cmd>cw<cr>")
map("n", "<leader>M", "")
map("n", "<leader>m", "=ip")
map("n", "<leader>N", "")
map("n", "<leader>n", "<cmd>NERDTree<cr>", { silent = true })
map("n", "<leader>O", "")
map("n", "<leader>o", "<cmd>cd %:p:h<CR>", { silent = true })
map("n", "<leader>P", "")
map("n", "<leader>p", "<cmd>lua MiniExtra.pickers.colorschemes()<CR>")
map("n", "<leader>Q", "")
map("n", "<leader>R", "qq", { desc = "Record Macro to 'q'" })
map("n", "<leader>r", "q")
map("n", "<leader>S", ":%s//<left>")
map("n", "<leader>s", "ma")
map("n", "<leader>T", ":nmap ")
map("n", "<leader>t", '<cmd>lua MiniSessions.read("0")<CR>')
map("n", "<leader>U", "<cmd>lua MiniPick.builtin.buffers()<CR>")
map("n", "<leader>V", "")
map("n", "<leader>v", "<cmd>TZNarrow<CR>")
map("n", "<leader>W", "")
map("n", "<leader>w", require("plugins.QDtb.lua_format").format, { desc = "Run Formatting" })
map("n", "<leader>X", "<cmd>Telescope find_files<CR>", { silent = true })
map("n", "<leader>Y", "")
map("n", "<leader>y", "<cmd>Telescope live_grep<CR>", { silent = true })
map("n", "<leader>Z", "")
map("n", "<leader>z", function()
    local input = vim.fn.input("Help: ", "", "help")
    if input ~= "" then
        vim.cmd("help " .. input)
        vim.cmd("only")
    end
end, { desc = "Open help in single window" })
map("n", "<leader>/", "<cmd>lua MiniPick.builtin.files()<CR>")
-- }}}
-- User General & Mode Mappings {{{
-- Stable
map("n", "<CR>", "yyp")
-- map("v", "v", "<ESC>Vc")
-- map("n", "<S-CR>", "dd O")
-- map("i", "<S-CR>", "<ESC>dd O")
map("i", "<C-CR>", "<ESC>o")
-- map("n", "<C-CR>", "}i")
map("i", "<C-S-CR>", "<ESC>O")
-- map("n", "<C-S-CR>", "{i")
map("n", "<BS>", "<LEFT><DEL>")
map("v", "<BS>", "x")
-- map("n", "<S-BS>", "<C-i>")
map("i", "<A-BS>", "<ESC>ciw")
map("n", "<A-BS>", "diw")
map("i", "<C-BS>", "<ESC><RIGHT>dbi")
map("n", "<C-BS>", "db")
map("n", "/", "<cmd>Telescope find_files<CR>")
map("n", "A", "v")
map("n", "a", "V")
map("n", "ds", "d/")
map("n", "dl", "dl")
map("n", "E", "<cmd>pwd<CR>")
map("n", "e", ":Startify<CR>", { silent = true })
map("n", "f", "z")
map("n", "ff", "zz")
map("n", "fj", "zt")
map("n", "fk", "zb")
map("n", "ft", "zf")
map("n", "[f", "[z")
map("n", "]f", "]z")
local fold_this = require("plugins.fold_this.fold_this")
map("n", "zq", function()
	fold_this.set_marker(false)
end, { desc = "Fold: marker method" })
map("n", "zQ", function()
	fold_this.set_marker(true)
end, { desc = "Fold: marker method, close all" })
map("n", "zY", function()
	local win = vim.api.nvim_get_current_win()
	vim.w[win].fold_this_marker = nil
	fold_this.apply_default(win, vim.api.nvim_get_current_buf())
end, { desc = "Fold: revert to treesitter/indent" })
map("n", "G", "GzR")
map("n", "gg", "ggzM")
map("n", "I", "a")
map("n", "L", "l")
map({ "n", "v" }, "M", "zM{zozz")
map({ "n", "v" }, "Q", ":qa<cr>")
map({ "n", "v" }, "q", ":q<cr>")
map("n", "R", "'azo")
map("n", "r", "/")
map({ "n", "x", "o" }, "s", "<Plug>(leap)")
map("n", "U", "<cmd>cd %:p:h<CR>")
map("n", "V", "A")
map("n", "X", "x")
map("n", "x", "@q")
map("n", ",", "h")
map({ "n", "v" }, "`", "~")
map("i", "<c-l>", "<c-o>J")
-- Save/Undo/Redo
map({ "i", "x", "n", "s" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save File" })
map("n", "<c-z>", "u")
map({ "i", "v" }, "<c-z>", "<c-o>u")
-- MiniFiles
map("n", "-", function()
	require("mini.files").open()
end, { noremap = true, silent = true, desc = "Open MiniFiles" })
map("n", "h", function()
	require("mini.files").open(vim.api.nvim_buf_get_name(0))
end, { noremap = true, silent = true, desc = "Open MiniFiles" })
-- Mouse / Misc Control Maps
map("n", "<X2Mouse>", "<c-i>")
map("n", "<X1Mouse>", "<c-o>")
-- Emacs Movement Keys
map("n", "<c-a>", "|")
map("i", "<c-a>", "<ESC>|i")
map("i", "<c-b>", "<LEFT>")
map("i", "<c-e>", "<ESC>A")
map("i", "<c-f>", "<RIGHT>")
map("i", "<c-d>", "<DEL>")
-- }}}
-- LazyVim Default Mappings {{{
-- Better up/down
map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
map({ "n", "x" }, "<Down>", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })
map({ "n", "x" }, "<Up>", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })
-- Move to window using the <ctrl> hjkl keys
map("n", "<C-h>", "<C-w>h", { desc = "Go to Left Window", remap = true })
map("n", "<C-j>", "<C-w>j", { desc = "Go to Lower Window", remap = true })
map("n", "<C-k>", "<C-w>k", { desc = "Go to Upper Window", remap = true })
map("n", "<C-l>", "<C-w>l", { desc = "Go to Right Window", remap = true })
-- Resize window using <ctrl> arrow keys
map("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase Window Height" })
map("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease Window Height" })
map("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease Window Width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase Window Width" })
-- Move Lines
map("n", "<A-j>", "<cmd>execute 'move .+' . v:count1<cr>==", { desc = "Move Down" })
map("n", "<A-k>", "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==", { desc = "Move Up" })
map("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move Down" })
map("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move Up" })
map("v", "<A-j>", ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv", { desc = "Move Down" })
map("v", "<A-k>", ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv", { desc = "Move Up" })
-- Clear search on escape
map({ "i", "n", "s" }, "<esc>", "<cmd>noh<cr><esc>", { desc = "Escape and Clear hlsearch" })
-- Clear search, diff update and redraw
map(
	"n",
	"<leader>ur",
	"<Cmd>nohlsearch<Bar>diffupdate<Bar>normal! <C-L><CR>",
	{ desc = "Redraw / Clear hlsearch / Diff Update" }
)
-- Saner behavior of n and N
map("n", "n", "'Nn'[v:searchforward].'zv'", { expr = true, desc = "Next Search Result" })
map("x", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next Search Result" })
map("o", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next Search Result" })
map("n", "N", "'nN'[v:searchforward].'zv'", { expr = true, desc = "Prev Search Result" })
map("x", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev Search Result" })
map("o", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev Search Result" })
-- Add undo break-points
map("i", ",", ",<c-g>u")
map("i", ".", ".<c-g>u")
map("i", ";", ";<c-g>u")
-- Better indenting
map("x", "<", "<gv")
map("x", ">", ">gv")
-- Commenting
map("n", "gco", "o<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>", { desc = "Add Comment Below" })
map("n", "gcO", "O<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>", { desc = "Add Comment Above" })
-- New file
map("n", "<leader>fn", "<cmd>enew<cr>", { desc = "New File" })
-- Location and Quickfix lists
map("n", "<leader>xl", function()
	local success, err = pcall(function()
		if vim.fn.getloclist(0, { winid = 0 }).winid ~= 0 then
			vim.cmd.lclose()
		else
			vim.cmd.lopen()
		end
	end)
	if not success and err then
		vim.notify(err, vim.log.levels.ERROR)
	end
end, { desc = "Location List" })
map("n", "<leader>xq", function()
	local success, err = pcall(function()
		if vim.fn.getqflist({ winid = 0 }).winid ~= 0 then
			vim.cmd.cclose()
		else
			vim.cmd.copen()
		end
	end)
	if not success and err then
		vim.notify(err, vim.log.levels.ERROR)
	end
end, { desc = "Quickfix List" })
map("n", "[q", vim.cmd.cprev, { desc = "Previous Quickfix" })
map("n", "]q", vim.cmd.cnext, { desc = "Next Quickfix" })
-- Diagnostics
local diagnostic_goto = function(next, severity)
	return function()
		vim.diagnostic.jump({
			count = (next and 1 or -1) * vim.v.count1,
			severity = severity and vim.diagnostic.severity[severity] or nil,
			on_jump = function(_, bufnr)
				vim.diagnostic.open_float({ bufnr = bufnr, scope = "cursor", focus = false })
			end,
		})
	end
end
map("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Line Diagnostics" })
map("n", "]d", diagnostic_goto(true), { desc = "Next Diagnostic" })
map("n", "[d", diagnostic_goto(false), { desc = "Prev Diagnostic" })
map("n", "]e", diagnostic_goto(true, "ERROR"), { desc = "Next Error" })
map("n", "[e", diagnostic_goto(false, "ERROR"), { desc = "Prev Error" })
map("n", "]w", diagnostic_goto(true, "WARN"), { desc = "Next Warning" })
map("n", "[w", diagnostic_goto(false, "WARN"), { desc = "Prev Warning" })
-- Utilities
map("n", "<leader>qq", "<cmd>qa<cr>", { desc = "Quit All" })
map("n", "<leader>ui", vim.show_pos, { desc = "Inspect Pos" })
map("n", "<leader>uI", function()
	vim.treesitter.inspect_tree()
	vim.api.nvim_input("I")
end, { desc = "Inspect Tree" })
-- Windows & Tabs
map("n", "<leader>-", "<C-W>s", { desc = "Split Window Below", remap = true })
map("n", "<leader>|", "<C-W>v", { desc = "Split Window Right", remap = true })
map("n", "<leader>wd", "<C-W>c", { desc = "Delete Window", remap = true })
map("n", "<leader><tab>l", "<cmd>tablast<cr>", { desc = "Last Tab" })
map("n", "<leader><tab>o", "<cmd>tabonly<cr>", { desc = "Close Other Tabs" })
map("n", "<leader><tab>f", "<cmd>tabfirst<cr>", { desc = "First Tab" })
map("n", "<leader><tab><tab>", "<cmd>tabnew<cr>", { desc = "New Tab" })
map("n", "<leader><tab>]", "<cmd>tabnext<cr>", { desc = "Next Tab" })
map("n", "<leader><tab>d", "<cmd>tabclose<cr>", { desc = "Close Tab" })
map("n", "<leader><tab>[", "<cmd>tabprevious<cr>", { desc = "Previous Tab" })
-- }}}
-- Footer
-- vim:foldmethod=marker:foldlevel=1
