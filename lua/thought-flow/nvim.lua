local M = {}

M.open_file_at_line = function(filename, line_number)
	-- Check if the line number is valid
	if line_number < 1 then
		print("Invalid line number")
		return
	end

	local buf = M.find_existing_buffer(filename)
	if buf == nil then
		buf = vim.api.nvim_create_buf(false, false) -- false = listed, false = non-scratch buffer
		vim.api.nvim_buf_set_name(buf, filename)
		-- Open the file in the new buffer
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, {}) -- Clear buffer contents if necessary
		vim.api.nvim_command("edit " .. filename)
	end
	-- Switch to the buffer
	vim.api.nvim_set_current_buf(buf)

	-- Move the cursor to the specified line number
	vim.defer_fn(function()
		-- Move the cursor to the specified line number
		vim.api.nvim_win_set_cursor(0, { line_number, 0 })
	end, 500) -- Adjust delay if necessary
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
