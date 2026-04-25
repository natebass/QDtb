--- Keymaps Configuration.
--- Sets up global, leader, and plugin-specific keybindings.
--- @module config.keymaps

local map = vim.keymap.set
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"
-- Special {{{
-- Package JSON Check
local package_json_path = "C:\\Users\\nateb\\Source\\Repos\\be-gccpilot03-py\\frontend\\package.json"
local package_json_dir = vim.fn.fnamemodify(package_json_path, ":h")
local pj = require("../plugins.QDtb.package_json")
map("n", "<leader>z", pj.check_npm_project, { desc = "Check if NPM project." })
-- Colorscheme
local colorscheme_cycler = require("../plugins.QDtb.colorscheme_cycler")
vim.cmd.colorscheme("default")
if type(colorscheme_cycler) == "table" and colorscheme_cycler.init_colorschemes then
	colorscheme_cycler.init_colorschemes()
else
	print("ERROR: colorscheme_cycler module not loaded correctly")
end
map("n", "<leader>b", colorscheme_cycler.next_colorscheme, { desc = "Next Colorscheme", silent = true })
vim.cmd.colorscheme("vague")
-- Focus & Leap
require("focus").setup()
map({ "n", "x", "o" }, "s", "<plug>(leap-forward)")
map({ "n", "x", "o" }, "S", "<plug>(leap-backward)")
map({ "n", "x", "o" }, "gs", "<plug>(leap-from-window)")
map({ "n", "x", "o" }, "gS", "<plug>(leap)")
-- }}}
-- User Leader Mappings {{{
map("n", "<leader>a", "<cmd>silent !npx prettier --write % &<CR>", { silent = true })
map("n", "<leader>B", "<cmd>Telescope buffers<CR>", { silent = true })
map("n", "<leader>C", "<cmd>Telescope help_tags<CR>", { silent = true })
map("n", "<leader>c", "<cmd>lua MiniPick.builtin.cli()<CR>")
map("n", "<leader>D", "<cmd>Telescope colorscheme<CR>", { silent = true })
map("n", "<leader>d", "<cmd>lua MiniPick.builtin.grep_live()<CR>")
map("n", "<leader>e", "<cmd>lua MiniPick.builtin.grep()<CR>")
map("n", "<leader>F", ":restart<cr>")
map("n", "<leader>f", ":<up><cr>")
map("n", "<leader>g", ":set wrap<cr>:Goyo<cr>")
map("n", "<leader>H", "<cmd>lua MiniPick.builtin.help()<CR>", { desc = "MiniPick Help" })
map("n", "<leader>h", ":set nowrap<cr>:Goyo<cr>", { silent = true })
map("n", "<leader>i", ":Limelight!!<cr>", { silent = true })
map("n", "<leader>J", ":<c-p><cr>")
map("n", "<leader>j", ":<c-p>")
map("n", "<leader>K", "/<c-f>")
map("n", "<leader>k", "/<up>")
map("n", "<leader>l", ":cw<cr>")
map("n", "<leader>m", "=ip")
map("n", "<leader>n", ":NERDTree<cr>", { silent = true })
map("n", "<leader>o", "<cmd>set nowrap<cr><cmd>Goyo<cr>", { silent = true })
map(
	"n",
	"<leader>P",
	string.format(":e %s<CR>:cd %s<CR>:NERDTreeToggle<CR><c-w>l", package_json_path, package_json_dir),
	{ desc = "Open Package JSON in NERDTree" }
)
map("n", "<leader>p", "<cmd>lua MiniExtra.pickers.colorschemes()<CR>")
map("n", "<leader>q", "<cmd>lua MiniPick.builtin.help()<CR>")
map("n", "<leader>R", "qr", { desc = "Record Macro to 'r'" })
map("n", "<leader>r", "q")
map("n", "<leader>s", ":%s//<left>")
map("n", "<leader>t", '<cmd>lua MiniSessions.read("0")<CR>')
map("n", "<leader>u", "<cmd>lua MiniPick.builtin.buffers()<CR>")
map("n", "<leader>v", "<cmd>TZNarrow<CR>")
map("n", "<leader>w", require("plugins.QDtb.lua_format").format, { desc = "Run Formatting" })
map("n", "<leader>x", "<cmd>Telescope find_files<CR>", { silent = true })
map("n", "<leader>y", "<cmd>Telescope live_grep<CR>", { silent = true })
map("n", "<leader>.", ":cd %:p:h<CR>", { silent = true })
-- TODO: Fix capital K not working.
-- LazyVim's Keywordprg (Previously on <leader>K)
-- map("n", "<leader>ck", "<cmd>norm! K<cr>", { desc = "Keywordprg" })
-- }}}
-- User General & Mode Mappings {{{
-- Under development
local package_json_path = "C:\\Users\\nateb\\Source\\Repos\\be-gccpilot03-py\\frontend\\package.json"
local package_json_dir = vim.fn.fnamemodify(package_json_path, ":h")
vim.keymap.set(
	"n",
	"h",
	string.format(":e %s<CR>:cd %s<CR>:NERDTreeToggle<CR><c-w>l", package_json_path, package_json_dir)
)
-- Stable
map("n", "<CR>", "yyp")
map("n", "<S-CR>", "dd O")
map("i", "<S-CR>", "<ESC>dd O")
map("i", "<C-CR>", "<ESC>}i")
map("n", "<C-CR>", "}i")
map("i", "<C-S-CR>", "<ESC>{i")
map("n", "<C-S-CR>", "{i")
map("n", "<BS>", "<LEFT><DEL>")
map("v", "<BS>", "x")
map("n", "<S-BS>", "<C-i>")
map("i", "<A-BS>", "<ESC>dd O")
map("n", "<A-BS>", "dd O")
map("i", "<C-BS>", "<ESC><RIGHT>dbi")
map("n", "<C-BS>", "db")
vim.keymap.set("n", "<c-l>", "J")
vim.keymap.set({ "i", "v" }, "<c-l>", "<c-o>J")
-- map("n", "/", "<cmd>lua MiniPick.builtin.files()<CR>")
vim.keymap.set("n", "/", "<cmd>Telescope find_files<CR>")
vim.keymap.set("n", "A", "v")
vim.keymap.set("n", "a", "V")
vim.keymap.set("n", "b", "mA")
vim.keymap.set("n", "ds", "d/")
map("n", "E", "<cmd>cd %:p:h<CR>")
vim.keymap.set("n", "e", ":Startify<CR>", { silent = true })
-- vim.keymap.set('n', 'f', 'z')
vim.keymap.set("n", "fd", "zd")
vim.keymap.set("n", "fE", "zE")
vim.keymap.set("n", "ff", "zz")
vim.keymap.set("n", "fj", "zt")
vim.keymap.set("n", "fk", "zk")
vim.keymap.set("n", "fm", "zm")
vim.keymap.set("n", "fM", "zM")
vim.keymap.set("n", "fo", "zo")
vim.keymap.set("n", "fO", "zO")
vim.keymap.set("n", "fr", "zr")
vim.keymap.set("n", "fR", "zR")
vim.keymap.set("n", "ft", "zf")
vim.keymap.set("n", "[f", "[z")
vim.keymap.set("n", "]f", "]z")
vim.keymap.set("n", "G", "Gzm")
map("n", "gg", "ggzM")
vim.keymap.set("n", "I", "a")
vim.keymap.set("n", "L", "l")
vim.keymap.set("n", "l", "f")
vim.keymap.set({ "n", "v" }, "M", "zM{zozz")
vim.keymap.set("n", "m", "F")
vim.keymap.set("v", "m", "F")
vim.keymap.set("n", "Q", ":qa<cr>")
vim.keymap.set("n", "q", ":q<cr>")
map("n", "R", "q")
vim.keymap.set("n", "r", "/")
vim.keymap.set({ "n", "x", "o" }, "s", "<Plug>(leap)")
map("n", "X", "x")
vim.keymap.set("n", "t", "'Azo")
map("n", "U", "<cmd>cd %:p:h<CR>")
map("n", "V", "A")
vim.keymap.set("n", "v", "Vc")
vim.keymap.set("v", "v", "<ESC>Vc")
vim.keymap.set("n", "w", "<c-w>")
vim.keymap.set("n", "X", "x")
vim.keymap.set("n", "x", "<c-i>")
vim.keymap.set("n", "z", "<c-o>")
vim.keymap.set("n", ",", "h")
vim.keymap.set({ "n", "v" }, "`", "~")
map({ "i", "x", "n", "s" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save File" })
-- Undo/Redo
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
-- Buffers
map("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Prev Buffer" })
map("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next Buffer" })
map("n", "[b", "<cmd>bprevious<cr>", { desc = "Prev Buffer" })
map("n", "]b", "<cmd>bnext<cr>", { desc = "Next Buffer" })
map("n", "<leader>bb", "<cmd>e #<cr>", { desc = "Switch to Other Buffer" })
map("n", "<leader>`", "<cmd>e #<cr>", { desc = "Switch to Other Buffer" })
map("n", "<leader>bD", "<cmd>:bd<cr>", { desc = "Delete Buffer and Window" })
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
	local success, err = pcall(vim.fn.getloclist(0, { winid = 0 }).winid ~= 0 and vim.cmd.lclose or vim.cmd.lopen)
	if not success and err then
		vim.notify(err, vim.log.levels.ERROR)
	end
end, { desc = "Location List" })
map("n", "<leader>xq", function()
	local success, err = pcall(vim.fn.getqflist({ winid = 0 }).winid ~= 0 and vim.cmd.cclose or vim.cmd.copen)
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
			float = true,
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
