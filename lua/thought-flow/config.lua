local __DEFAULT_OPTIONS = {
	path = vim.fn.stdpath("data") .. "/thought-flow.json",
	ui = {
		prompt = "> ",
	},
	-- swap with your choice of notification channel
	notifications = {
		error = function(msg)
			vim.notify(msg, vim.log.levels.ERROR, { title = "thought-flow" })
		end,
	},
	annotations = {
		text = "💭",
		namespace = "thought-flow-namespace",
		color = "#00bfff"
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
	autocmd = {
		group = "thought-flow",
		pattern = "*",
	},
}

local M = {}

M.options = __DEFAULT_OPTIONS
M.configure = function(user_options)
	M.options = vim.tbl_deep_extend("force", __DEFAULT_OPTIONS, user_options or {})
end
return M
