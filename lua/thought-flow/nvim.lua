local M = {}

local function remove_all_extmarks(ns_id, bufnr)
	-- Get all extmarks in the namespace
	local extmarks = vim.api.nvim_buf_get_extmarks(bufnr, ns_id, 0, -1, {})

	if extmarks == nil then
		return
	end
	for _, mark in ipairs(extmarks) do
		local id = mark[1]
		vim.api.nvim_buf_del_extmark(bufnr, ns_id, id)
	end
end

local function add_virtual_text(ns_id, bufnr, line, text, hl_group)
	-- Ensure the line number is zero-indexed
	line = line - 1

	-- Define the virtual text
	local virt_text = { { text, hl_group } }

	-- Add the virtual text to the buffer
	vim.api.nvim_buf_set_extmark(bufnr, ns_id, line, 0, {
		virt_text = virt_text,
		virt_text_pos = "eol", -- Position the virtual text at the end of the line
	})
end

local function file_exists(filepath)
	local stat = vim.loop.fs_stat(filepath)
	return stat and stat.type == "file"
end

M.init = function()
	local config = require("thought-flow.config")
	M.annotation_namespace = vim.api.nvim_create_namespace(config.options.annotations.namespace)
	vim.api.nvim_set_hl(0, "InfoSignHL", {
		fg = config.options.annotations.color, -- Foreground color (text color)
		bg = "NONE", -- Background color (use 'NONE' for no background)
		bold = true, -- Make the text bold
	})
end

M.annotate = function(bufnr, line_number)
	local config = require("thought-flow.config")
	add_virtual_text(M.annotation_namespace, bufnr, line_number, config.options.annotations.text, "InfoSignHL")
end

M.clear_annotations = function(bufnr)
	remove_all_extmarks(M.annotation_namespace, bufnr)
end

M.register_autocmd = function(callback)
	local config = require("thought-flow.config")
	vim.api.nvim_create_augroup(config.options.autocmd.group, { clear = true })

	-- Add autocommand to run your function on file load
	vim.api.nvim_create_autocmd("BufReadPost", {
		group = config.options.autocmd.group,
		pattern = config.options.autocmd.pattern, -- This pattern matches all files. You can specify a more specific pattern if needed.
		callback = function()
			callback()
		end,
	})
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
