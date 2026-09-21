--- Session actions built on vim-startify's session store.
--- @module "plugins.session_manager.sessions"
local M = {}
-- Store {{{
M.prefix = "<Leader>M"
local function load_startify()
	if vim.g.loaded_startify ~= 1 then
		vim.cmd.packadd("vim-startify")
	end
end
--- The one directory every session lives in.
--- Read back out of `vim.g` rather than recomputed, so Startify and this module cannot
--- end up pointing at different places.
--- @return string dir Absolute path to the session directory.
function M.dir()
	return vim.g.startify_session_dir
end
--- Full path of a session file.
--- @param name string Session name as shown in the Startify dashboard.
--- @return string path
function M.path(name)
	return vim.fs.joinpath(M.dir(), name)
end
--- Creates the session directory when it is missing.
--- `:SSave` would otherwise stop to ask whether to create it, a prompt with one answer.
--- @return string dir The session directory, now guaranteed to exist.
function M.ensure_dir()
	local dir = M.dir()
	if vim.fn.isdirectory(dir) == 0 then
		vim.fn.mkdir(dir, "p")
	end
	return dir
end
--- Drops Startify's `__LAST__` symlink when it no longer points at a file.
--- `:SLoad!` sources that link; a dangling one turns the load-last mapping into an error
--- message until the next save recreates it.
local function prune_last_link()
	local last = M.path("__LAST__")
	if vim.uv.fs_lstat(last) ~= nil and vim.uv.fs_stat(last) == nil then
		vim.fn.delete(last)
	end
end
--- Every saved session, most recently written first.
--- Startify's own lister is used so this can never disagree with the dashboard; the sort
--- happens here because `g:startify_session_sort` only affects the dashboard's rendering.
--- @return string[] names Session names, `__LAST__` excluded.
function M.list()
	load_startify()
	local ok, names = pcall(vim.fn["startify#session_list"], "")
	if not ok or type(names) ~= "table" then
		return {}
	end
	table.sort(names, function(a, b)
		return vim.fn.getftime(M.path(a)) > vim.fn.getftime(M.path(b))
	end)
	return names
end
-- }}}
-- Actions {{{
--- Session name for the current working directory.
--- Startify lists sessions by filename, so a readable basename beats an escaped full
--- path; `:SSave` still asks before overwriting when two projects share a basename.
--- @return string name
function M.cwd_name()
	local cwd = vim.fn.getcwd()
	local name = vim.fs.basename(cwd)
	if name == nil or name == "" then
		name = (cwd:gsub("%W", "_"))
	end
	return name
end
--- Closes windows owned by other plugins, so they do not serialise into a session.
--- Runs from `g:startify_session_before_save`, which executes each entry as a Vim
--- command -- so this has to be one command and cannot be an inline `:if`, because a
--- bar-separated `if`/`endif` inside `:execute` swallows the `:endfor` of the loop
--- Startify runs it from.
--- The `exists()` guards matter: `plugin/packages.lua` maps both commands to
--- `CmdUndefined`, so calling them blindly would load the package on every single save
--- just to close a window that was never open.
function M.close_side_panels()
	local has_nerdtree = vim.fn.exists(":NERDTreeClose") == 2
	local has_goyo = vim.fn.exists(":Goyo") == 2
	if not (has_nerdtree or has_goyo) then
		return
	end
	-- Both are per-tab, so every tab is visited and the starting one restored afterwards.
	local tab = vim.api.nvim_get_current_tabpage()
	for _, page in ipairs(vim.api.nvim_list_tabpages()) do
		if vim.api.nvim_tabpage_is_valid(page) then
			pcall(vim.api.nvim_set_current_tabpage, page)
			if has_nerdtree then
				pcall(vim.cmd, "silent! NERDTreeClose")
			end
			if has_goyo and vim.fn.exists("t:goyo_pads") == 1 then
				pcall(vim.cmd, "silent! Goyo!")
			end
		end
	end
	if vim.api.nvim_tabpage_is_valid(tab) then
		pcall(vim.api.nvim_set_current_tabpage, tab)
	end
end
--- Writes the session for the current directory without prompting.
function M.save_cwd()
	M.ensure_dir()
	local name = M.cwd_name()
	vim.cmd("SSave! " .. vim.fn.fnameescape(name))
	vim.notify("Session saved: " .. name)
end
--- Writes a session under a name typed by the user.
--- Startify's own prompt is used rather than a reimplementation because it completes
--- existing session names with <Tab> and pre-fills the current session's name.
function M.save_as()
	M.ensure_dir()
	vim.cmd("SSave")
end
--- Loads a session by name, or opens the picker when no name is given.
--- @param name string|nil Session name.
function M.load(name)
	if name == nil then
		return M.pick()
	end
	vim.cmd("SLoad " .. vim.fn.fnameescape(name))
end
--- Re-opens whichever session was used last, via Startify's `__LAST__` symlink.
function M.load_last()
	prune_last_link()
	vim.cmd("SLoad!")
end
--- Writes the current session, drops its buffers and returns to the dashboard.
function M.close()
	vim.cmd("SClose")
end
--- Deletes a session file.
--- `:SDelete` is not used here because it re-prompts for a name the caller already knows.
--- @param name string Session name.
--- @param opts table|nil Options. Fields: <confirm> (boolean, default true).
--- @return boolean ok True when the file was removed.
function M.delete(name, opts)
	opts = opts or {}
	local path = M.path(name)
	if vim.fn.filereadable(path) == 0 then
		vim.notify("No such session: " .. name, vim.log.levels.WARN)
		return false
	end
	if opts.confirm ~= false and vim.fn.confirm("Delete session '" .. name .. "'?", "&Yes\n&No", 2) ~= 1 then
		return false
	end
	if vim.fn.delete(path) ~= 0 then
		vim.notify("Could not delete session: " .. name, vim.log.levels.ERROR)
		return false
	end
	-- `v:this_session` would still name the file we just removed, and
	-- `startify_session_persistence` would faithfully recreate it on exit.
	if vim.v.this_session == path then
		vim.v.this_session = ""
	end
	prune_last_link()
	vim.notify("Deleted session: " .. name)
	return true
end
--- Renames a session file.
--- @param old string Current session name.
--- @param new string|nil New name. Prompts when nil.
--- @return boolean ok True when the file was renamed.
function M.rename(old, new)
	if new == nil then
		new = vim.fn.input({ prompt = "Rename session to: ", default = old })
	end
	if new == nil or new == "" or new == old then
		return false
	end
	-- A separator would put the file in a subdirectory, where Startify's flat glob over
	-- the session directory would never find it again.
	if new:find("[/\\]") then
		vim.notify("Session names cannot contain a path separator.", vim.log.levels.WARN)
		return false
	end
	local old_path, new_path = M.path(old), M.path(new)
	if vim.fn.filereadable(new_path) == 1 then
		vim.notify("Session already exists: " .. new, vim.log.levels.WARN)
		return false
	end
	local ok, err = vim.uv.fs_rename(old_path, new_path)
	if not ok then
		vim.notify("Rename failed: " .. tostring(err), vim.log.levels.ERROR)
		return false
	end
	if vim.v.this_session == old_path then
		vim.v.this_session = new_path
	end
	prune_last_link()
	vim.notify(("Renamed session %s to %s"):format(old, new))
	return true
end
-- }}}
-- Picker {{{
--- Opens a session picker with in-picker delete and rename.
--- mini.pick is already this config's picker, and its custom mappings can act on the item
--- under the cursor without tearing the list down, which is what managing several
--- sessions at once needs.
function M.pick()
	local names = M.list()
	if #names == 0 then
		return vim.notify("No sessions saved yet.", vim.log.levels.WARN)
	end
	local pick = require("mini.pick")
	--- @return string|nil name Session under the picker's cursor.
	local function current()
		local matches = pick.get_picker_matches()
		return matches and matches.current or nil
	end
	pick.start({
		source = {
			items = names,
			name = "Sessions",
			-- Loading wipes every buffer and rebuilds the window layout, so it waits until
			-- the picker window is actually gone.
			choose = function(item)
				vim.schedule(function()
					M.load(item)
				end)
			end,
		},
		mappings = {
			-- No confirmation: the list in front of you is the confirmation and the row
			-- disappearing is the feedback. A prompt would also draw over the picker, which
			-- owns the command line while it is open.
			delete = {
				char = "<C-d>",
				func = function()
					local item = current()
					if item ~= nil and M.delete(item, { confirm = false }) then
						pick.set_picker_items(M.list())
					end
				end,
			},
			-- Renaming needs the command line the picker is holding, so it stops the picker
			-- first and reopens afterwards with a refreshed list.
			rename = {
				char = "<C-r>",
				func = function()
					local item = current()
					if item == nil then
						return
					end
					vim.schedule(function()
						if M.rename(item) then
							M.pick()
						end
					end)
					return true
				end,
			},
		},
	})
end
-- }}}
-- Dashboard {{{
--- The managed session under the cursor in a Startify buffer, if any.
--- `b:startify.entries` is a Vim dict keyed by line number, so the key arrives in Lua as
--- a string. The cwd-local `Session.vim` entry is also `type == "session"` but lives
--- outside the session directory, so `cmd == "SLoad"` is what identifies one of ours.
--- @return string|nil name Session name, or nil when the cursor is on anything else.
function M.entry_under_cursor()
	local startify = vim.b.startify
	if type(startify) ~= "table" or type(startify.entries) ~= "table" then
		return nil
	end
	local entry = startify.entries[tostring(vim.fn.line("."))]
	if type(entry) ~= "table" or entry.type ~= "session" or entry.cmd ~= "SLoad" then
		return nil
	end
	return entry.path
end
--- Adds session actions to a Startify dashboard buffer.
--- Startify binds each entry's index key last, just before setting the filetype, so a
--- `FileType startify` mapping wins over them -- which is why these avoid keys that are
--- already indices: `d` and `r` are bookmark indices in this config.
--- @param buf integer Buffer to map in.
function M.map_dashboard(buf)
	local map = vim.keymap.set
	--- @param action fun(name: string): boolean
	--- @return function
	local function on_session(action)
		return function()
			local name = M.entry_under_cursor()
			if name == nil then
				return vim.notify("Not a saved session", vim.log.levels.WARN)
			end
			if action(name) then
				vim.cmd.Startify()
			end
		end
	end
	local opts = { buffer = buf, nowait = true }
	map("n", "D", on_session(M.delete), vim.tbl_extend("force", opts, { desc = "Delete session" }))
	map("n", "<C-d>", on_session(M.delete), vim.tbl_extend("force", opts, { desc = "Delete session" }))
	map("n", "<C-r>", on_session(M.rename), vim.tbl_extend("force", opts, { desc = "Rename session" }))
end
-- }}}
-- Keymaps {{{
--- Creates the leader mappings for every session action.
--- Called from `after/plugin/keymaps.lua` so the whole group, and the prefix it hangs
--- off, live in one place.
function M.map_leader()
	--- @param suffix string Key pressed after `M.prefix`.
	--- @param rhs function|string
	--- @param desc string
	local function session_map(suffix, rhs, desc)
		vim.keymap.set("n", M.prefix .. suffix, rhs, { desc = desc })
	end
	session_map("S", M.save_as, "Save Session As...")
	session_map("d", "<cmd>SDelete<cr>", "Delete Session (prompt)")
	session_map("f", M.pick, "Find Session (<C-d> delete, <C-r> rename)")
	session_map("l", M.load_last, "Load Last Session")
	session_map("q", M.close, "Close Session")
	session_map("s", M.save_cwd, "Save Session for this Directory")
end
-- }}}
return M
-- Footer
-- vim:foldmethod=marker:foldlevel=1
