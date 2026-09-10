--- Algorithm Quotes. Randomly select quote about algorithms for the Startify custom footer.
--- @module "plugins.session_manager.algorithm_quote"

local utility = require("lib.utility")

-- Seed once at load so each session picks a different quote.
math.randomseed(os.time())

local M = {}

-- Table of quotes about computer algorithms
-- Each entry is a table with 'text' and 'source'
local algorithm_quotes = {
	{
		text = "An algorithm must be seen to be believed.",
		source = "Donald Knuth",
	},
	{
		text = "The art of programming is the art of organizing complexity, of mastering multitude and making it tractable.",
		source = "Edsger W. Dijkstra",
	},
	{
		text = "Algorithms are just formalized recipes for doing something.",
		source = "Jeff Dean",
	},
	{
		text = "The function of a good algorithm is to hide the details of a problem, not to expose them.",
		source = "Unknown",
	},
	{
		text = "The best programs are the ones that are written by people who are thinking about the problem, not about the language.",
		source = "Paul Graham",
	},
	{
		text = "If you optimize everything, you will always be unhappy.",
		source = "Donald Knuth",
	},
	{
		text = "Premature optimization is the root of all evil (or at least most of it) in programming.",
		source = "Donald Knuth (often misattributed to Tony Hoare)",
	},
	{
		text = "The only truly secure system is one that is powered off, cast in a block of concrete, and sealed in a lead-lined room with armed guards - and even then, I have my doubts.",
		source = "Gene Spafford (on security algorithms)",
	},
	{
		text = "In theory, there is no difference between theory and practice. But in practice, there is.",
		source = "Jan L.A. van de Snepscheut (often applied to algorithm efficiency)",
	},
	{
		text = "Debugging is twice as hard as writing the code in the first place. Therefore, if you write the code as cleverly as you can, you are, by definition, not smart enough to debug it.",
		source = "Brian W. Kernighan",
	},
}

--- Returns a randomly selected quote formatted for Startify's custom footer.
--- @function quotes
--- @return table A table of strings, each representing a line for the footer.
function M.quotes()
	-- Get a random index
	local index = math.random(1, #algorithm_quotes)

	-- Get the selected quote
	local selected_quote = algorithm_quotes[index]

	-- Format the quote as required by Startify's custom footer
	local limit = math.max(20, vim.o.columns - 2)
	local text_with_quotes = '"' .. selected_quote.text .. '"'
	local wrapped_lines = utility.wrap_text(text_with_quotes, limit)

	local lines = { "" }
	for _, line in ipairs(wrapped_lines) do
		table.insert(lines, " " .. line)
	end
	table.insert(lines, " - " .. selected_quote.source)
	table.insert(lines, "")

	return lines
end

return M
