local M = {
	window = {
		mappings = {
			["<space>"] = "show_full_text",
			["d"] = "delete_thought",
		},
	},
}

M.renderers = {
	directory = {
		{ "indent" },
		{ "icon" },
		{ "name" },
	},
	thought = {
		{ "indent" },
		{ "icon" },
		{ "name" },
	},
}

return M
