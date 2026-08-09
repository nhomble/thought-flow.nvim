local M = {}

local function read_context_lines(file, line_number)
	local ok, bufnr = pcall(vim.fn.bufadd, file)
	if not ok then
		return nil
	end
	pcall(vim.fn.bufload, bufnr)

	local total = vim.api.nvim_buf_line_count(bufnr)
	if not vim.api.nvim_buf_is_loaded(bufnr) or line_number > total then
		return nil
	end

	local first = math.max(1, line_number - 1)
	local last = math.min(total, line_number + 1)
	return vim.api.nvim_buf_get_lines(bufnr, first - 1, last, false)
end

---@return string
function M.generate_markdown()
	local repo = require("thought-flow.repo")
	local all = repo.get_all()
	if next(all) == nil then
		return "No thoughts yet."
	end

	local by_file = {}
	local file_order = {}
	for key, data in pairs(all) do
		if by_file[data.file] == nil then
			by_file[data.file] = {}
			table.insert(file_order, data.file)
		end
		local group = by_file[data.file][data.line_number]
		if group == nil then
			group = {}
			by_file[data.file][data.line_number] = group
		end
		table.insert(group, key)
	end
	table.sort(file_order)

	local lines = {}
	local first_entry = true

	for _, file in ipairs(file_order) do
		local line_numbers = {}
		for line_number, _ in pairs(by_file[file]) do
			table.insert(line_numbers, line_number)
		end
		table.sort(line_numbers)

		for _, line_number in ipairs(line_numbers) do
			if not first_entry then
				table.insert(lines, "")
				table.insert(lines, "---")
				table.insert(lines, "")
			end
			first_entry = false

			table.insert(lines, string.format("**%s:%d**", file, line_number))
			table.insert(lines, "")

			local context = read_context_lines(file, line_number)
			if context then
				for _, context_line in ipairs(context) do
					table.insert(lines, "> " .. context_line)
				end
			else
				table.insert(lines, "> [orphaned: file or line no longer exists]")
			end

			table.insert(lines, "")
			table.insert(lines, "thoughts:")
			table.insert(lines, "")

			local thoughts_here = by_file[file][line_number]
			table.sort(thoughts_here)
			for _, text in ipairs(thoughts_here) do
				table.insert(lines, "- " .. text)
			end
		end
	end

	return table.concat(lines, "\n")
end

function M.to_clipboard()
	local repo = require("thought-flow.repo")
	local count = 0
	for _ in pairs(repo.get_all()) do
		count = count + 1
	end
	if count == 0 then
		vim.notify("No thoughts to export", vim.log.levels.WARN, { title = "thought-flow" })
		return
	end

	local markdown = M.generate_markdown()
	vim.fn.setreg("+", markdown)
	vim.fn.setreg("*", markdown)

	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_set_option_value("buftype", "nofile", { buf = buf })
	vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })
	vim.api.nvim_set_option_value("filetype", "markdown", { buf = buf })

	local body = vim.split(markdown, "\n", { plain = true })
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, body)
	vim.api.nvim_set_option_value("modifiable", false, { buf = buf })

	local prev_win = vim.api.nvim_get_current_win()
	vim.cmd("botright " .. math.min(#body + 1, 15) .. "split")
	vim.api.nvim_win_set_buf(0, buf)

	vim.keymap.set("n", "q", function()
		vim.api.nvim_win_close(0, true)
		if vim.api.nvim_win_is_valid(prev_win) then
			vim.api.nvim_set_current_win(prev_win)
		end
	end, { buffer = buf, nowait = true })

	vim.notify(
		string.format("Exported %d thought(s) to clipboard", count),
		vim.log.levels.INFO,
		{ title = "thought-flow" }
	)
end

return M
