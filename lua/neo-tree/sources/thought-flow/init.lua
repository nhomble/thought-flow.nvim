local renderer = require("neo-tree.ui.renderer")

local M = {
	name = "thought-flow",
	display_name = " \u{f075} Thoughts ",
	default_config = require("neo-tree.sources.thought-flow.defaults"),
}

local function is_orphaned(thought_data)
	local stat = vim.loop.fs_stat(thought_data.file)
	if not stat or stat.type ~= "file" then
		return true
	end

	local ok, file_bufnr = pcall(vim.fn.bufadd, thought_data.file)
	if not ok then
		return true
	end
	pcall(vim.fn.bufload, file_bufnr)

	return thought_data.line_number > vim.api.nvim_buf_line_count(file_bufnr)
end

local function truncate_text(text, max_width)
	max_width = max_width or 50
	if #text <= max_width then
		return text
	end
	return text:sub(1, max_width - 3) .. "..."
end

M.navigate = function(state, path, path_to_reveal, callback, async)
	state.path = path or state.path or vim.fn.getcwd()

	local config = require("thought-flow.config")
	local repo = require("thought-flow.repo")

	local files = {}
	local file_order = {}
	for key, thought_data in pairs(repo.get_all()) do
		local file = thought_data.file
		if files[file] == nil then
			files[file] = {}
			table.insert(file_order, file)
		end
		table.insert(files[file], { key = key, data = thought_data, orphaned = is_orphaned(thought_data) })
	end
	table.sort(file_order)

	if #file_order == 0 then
		renderer.show_nodes({
			{ id = "__no_thoughts__", name = "No thoughts captured yet", type = "message" },
		}, state)
		if type(callback) == "function" then
			vim.schedule(callback)
		end
		return
	end

	state.default_expanded_nodes = file_order

	local items = {}
	for _, file in ipairs(file_order) do
		local thoughts = files[file]
		table.sort(thoughts, function(a, b)
			return a.data.line_number < b.data.line_number
		end)

		local children = {}
		for _, thought in ipairs(thoughts) do
			local indicator = thought.orphaned and (config.options.orphaned.indicator or "[!] ") or ""
			table.insert(children, {
				id = file .. "::" .. thought.key,
				name = indicator .. truncate_text(thought.key, config.options.ui.max_thought_display_width),
				type = "thought",
				extra = {
					thought_flow = thought.data,
					original_text = thought.key,
					is_orphaned = thought.orphaned,
				},
			})
		end

		table.insert(items, {
			id = file,
			name = vim.fn.fnamemodify(file, ":~:."),
			type = "directory",
			children = children,
		})
	end

	renderer.show_nodes(items, state)

	if path_to_reveal then
		renderer.focus_node(state, path_to_reveal, false)
	end

	if type(callback) == "function" then
		vim.schedule(callback)
	end
end

M.setup = function(config, global_config) end

return M
