local __DEFAULT_OPTIONS = {
	path = vim.fn.stdpath("data") .. "/thought-flow.json",
	ui = {
		prompt = "> ",
	},
	-- in case users want to swap out the internal deser
	json = {
		decode = function(s)
			return vim.json.decode(s)
		end,
		encode = function(o)
			return vim.json.encode(o)
		end,
	},
}

local M = {}

M.options = __DEFAULT_OPTIONS
M.configure = function(user_options)
	vim.tbl_deep_extend("keep", user_options or {}, __DEFAULT_OPTIONS)
end
return M
