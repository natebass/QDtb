--- Autosave Configuration.
--- Writes modified file buffers when Neovim loses focus or is about to exit.
--- @module "plugins.QDtb.autosave"

local M = {}

--- Buffer types that never hold a file worth writing.
local skipped_buftypes = {
	acwrite = true,
	help = true,
	nofile = true,
	nowrite = true,
	prompt = true,
	quickfix = true,
	terminal = true,
}

--- Filetypes whose buffer is owned by another tool and must not be written behind its back.
local skipped_filetypes = {
	gitcommit = true,
	gitrebase = true,
	hgcommit = true,
	minifiles = true,
	oil = true,
	startify = true,
}

--- Decides whether a buffer is an ordinary file with unsaved changes.
--- Buffer properties are checked instead of a filetype allowlist: any real file is
--- worth saving, and the buffer itself already knows whether it can be written.
--- @param bufnr integer The buffer to inspect.
--- @return boolean True when the buffer should be written.
function M.should_save(bufnr)
	if not vim.api.nvim_buf_is_valid(bufnr) or not vim.api.nvim_buf_is_loaded(bufnr) then
		return false
	end

	local buffer = vim.bo[bufnr]
	if not buffer.modified or not buffer.modifiable or buffer.readonly then
		return false
	end
	if skipped_buftypes[buffer.buftype] or skipped_filetypes[buffer.filetype] then
		return false
	end

	local name = vim.api.nvim_buf_get_name(bufnr)
	if name == "" then
		return false
	end
	-- A buffer behind a URL scheme (fugitive://, oil://, ...) is not an ordinary file.
	if name:find("^%a[%w+.-]*://") then
		return false
	end

	return true
end

--- Writes every buffer that M.should_save accepts.
--- Unlike `:wa` this touches only the buffers that were checked, and a buffer that
--- refuses to write is reported instead of being swallowed by `silent!`.
--- @return integer saved The number of buffers written.
function M.save_all()
	local saved = 0
	for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
		if M.should_save(bufnr) then
			local ok, err = pcall(vim.api.nvim_buf_call, bufnr, function()
				vim.cmd("silent write")
			end)
			if ok then
				saved = saved + 1
			else
				vim.notify(
					("Autosave failed for %s: %s"):format(
						vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":~:."),
						err
					),
					vim.log.levels.WARN
				)
			end
		end
	end
	return saved
end

local augroup = vim.api.nvim_create_augroup("QDtbAutosave", { clear = true })

vim.api.nvim_create_autocmd({ "FocusLost", "VimLeavePre" }, {
	group = augroup,
	callback = function()
		-- Set vim.g.QDtb_autosave to false to turn autosaving off for the session.
		if vim.g.QDtb_autosave == false then
			return
		end
		M.save_all()
	end,
	desc = "Write modified file buffers on focus loss and before exiting",
})

return M
