local M = {}
local function file_exists(filepath)
	local stat = vim.loop.fs_stat(filepath)
	return stat and stat.type == "file"
end

M.go_to_line = function(line_number)
	-- Get the total number of lines in the current buffer
	local total_lines = vim.api.nvim_buf_line_count(0)

	-- Ensure the line number is within the buffer's range
	if line_number > total_lines then
		line_number = total_lines
	end

	-- Move the cursor to the specified line number
	vim.api.nvim_win_set_cursor(0, { line_number, 0 })
end

M.open_file_at_line = function(filename, line_number)
	local notifications = require("thought-flow.config").options.notifications
	-- Check if the line number is valid
	if line_number < 1 then
		notifications.error("Line number is less than 0: " .. line_number)
		return
	end

	if not file_exists(filename) then
		notifications.error("Unknown file: [" .. filename .. "]")
		return
	end

	local buf = M.find_existing_buffer(filename)
	if buf == nil then
		buf = vim.api.nvim_create_buf(false, false) -- false = listed, false = non-scratch buffer
		vim.api.nvim_buf_set_name(buf, filename)
		vim.api.nvim_set_current_buf(buf)
		vim.api.nvim_command("edit " .. filename)
	end
	-- Switch to the buffer
	vim.api.nvim_set_current_buf(buf)

	M.go_to_line(line_number)
end

M.find_existing_buffer = function(filename)
	local buf_list = vim.api.nvim_list_bufs()

	for _, b in ipairs(buf_list) do
		if vim.api.nvim_buf_get_name(b) == filename then
			return b
		end
	end

	return nil
end

return M
