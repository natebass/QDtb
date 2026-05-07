--- Bible Verses. Randomly selected Bible verses for the Startify custom header.
--- @module plugins.session_manager.bible_verse

local M = {}

-- Table of Bible verses
-- Each entry is a table with 'text' and 'source'
local bible_verses = {
	{
		text = "For God so loved the world, that he gave his only Son, that whoever believes in him should not perish but have eternal life.",
		source = "John 3:16",
	},
	{
		text = "I can do all things through him who strengthens me.",
		source = "Philippians 4:13",
	},
	{
		text = "Trust in the LORD with all your heart, and do not lean on your own understanding.",
		source = "Proverbs 3:5",
	},
	{
		text = "The LORD is my shepherd; I shall not want.",
		source = "Psalm 23:1",
	},
	{
		text = "And we know that for those who love God all things work together for good, for those who are called according to his purpose.",
		source = "Romans 8:28",
	},
	{
		text = "Be strong and courageous. Do not be frightened, and do not be dismayed, for the LORD your God is with you wherever you go.",
		source = "Joshua 1:9",
	},
	{
		text = "For I know the plans I have for you, declares the LORD, plans for welfare and not for evil, to give you a future and a hope.",
		source = "Jeremiah 29:11",
	},
	{
		text = "But the fruit of the Spirit is love, joy, peace, patience, kindness, goodness, faithfulness, gentleness, self-control; against such things there is no law.",
		source = "Galatians 5:22-23",
	},
	{
		text = "In the beginning, God created the heavens and the earth.",
		source = "Genesis 1:1",
	},
	{
		text = "Rejoice always, pray without ceasing, give thanks in all circumstances; for this is the will of God in Christ Jesus for you.",
		source = "1 Thessalonians 5:16-18",
	},
}

local function wrap_text(text, limit)
	local lines = {}
	local current_line = ""
	for word in text:gmatch("%S+") do
		if #current_line + #word + 1 > limit then
			table.insert(lines, current_line)
			current_line = word
		else
			if current_line == "" then
				current_line = word
			else
				current_line = current_line .. " " .. word
			end
		end
	end
	if current_line ~= "" then
		table.insert(lines, current_line)
	end
	return lines
end

--- Returns a randomly selected quote formatted for Startify's custom footer.
--- @function quotes
--- @return table A table of strings, each representing a line for the footer.
function M.quotes()
	-- Seed the random number generator if not already seeded
	-- This is important to get different quotes each time Neovim starts
	math.randomseed(os.time())

	-- Get a random index
	local index = math.random(1, #bible_verses)

	-- Get the selected quote
	local selected_quote = bible_verses[index]

	-- Format the quote as required by Startify's custom footer
	local wrapped_lines = wrap_text(selected_quote.text, 78)
	table.insert(wrapped_lines, selected_quote.source)

	-- Center the lines and add side padding
	local columns = vim.o.columns
	local centered_lines = {}
	for _, line in ipairs(wrapped_lines) do
		local padded_line_width = vim.api.nvim_strwidth(line) + 2 -- +2 for the spaces on both sides
		local padding_size = math.max(0, math.floor((columns - padded_line_width) / 2))
		table.insert(centered_lines, string.rep(" ", padding_size) .. " " .. line)
	end

	return centered_lines
end

return M
