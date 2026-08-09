local M = {}

-- Status cache for performance
local _status_cache = nil

local function invalidate_status_cache()
	_status_cache = nil
end

M.invalidate_status_cache = invalidate_status_cache

local function refresh_tree()
	local ok, manager = pcall(require, "neo-tree.sources.manager")
	if not ok then
		return
	end
	local ok_renderer, renderer = pcall(require, "neo-tree.ui.renderer")
	if not ok_renderer then
		return
	end

	local state = manager.get_state("thought-flow")
	if state and renderer.window_exists(state) then
		manager.refresh("thought-flow")
	end
end

M.init = function()
	-- Check for required dependencies
	local ok_nui, _ = pcall(require, "nui.input")
	if not ok_nui then
		vim.notify(
			"thought-flow.nvim requires nui.nvim. Install it with your plugin manager.",
			vim.log.levels.ERROR,
			{ title = "thought-flow.nvim" }
		)
		return false
	end

	require("thought-flow.repo").init()
	local nvim = require("thought-flow.nvim")
	nvim.init()
	nvim.register_autocmd(function()
		M.annotate_buffer()
	end)

	-- Create user commands
	vim.api.nvim_create_user_command("ThoughtFlowCapture", M.capture, {
		desc = "Capture a thought at the current cursor position",
	})
	vim.api.nvim_create_user_command("ThoughtFlowReview", M.review, {
		desc = "Review all captured thoughts",
	})
	vim.api.nvim_create_user_command("ThoughtFlowClear", M.clear, {
		desc = "Clear all thoughts",
	})
	vim.api.nvim_create_user_command("ThoughtFlowRemoveLine", M.remove_line, {
		desc = "Remove thought at current cursor line",
	})
	vim.api.nvim_create_user_command("ThoughtFlowNext", M.goto_next, {
		desc = "Go to next thought in current file",
	})
	vim.api.nvim_create_user_command("ThoughtFlowPrev", M.goto_prev, {
		desc = "Go to previous thought in current file",
	})

	return true
end

M.setup = function(options)
	require("thought-flow.config").configure(options)
	if not M._initialized then
		local success = M.init()
		if success then
			M._initialized = true
		end
	end
end

M.clear = function()
	local repo = require("thought-flow.repo")
	repo.clear()
	M.annotate_buffer()
	invalidate_status_cache()
	refresh_tree()
end

M.annotate_buffer = function(bufnr)
	if bufnr == nil then
		bufnr = vim.api.nvim_get_current_buf()
	end
	local repo = require("thought-flow.repo")
	local nvim = require("thought-flow.nvim")
	local thought_file = vim.api.nvim_buf_get_name(bufnr)
	local file_thoughts = repo.find_thoughts_for_file(thought_file)
	nvim.clear_annotations(bufnr)
	for _, value in pairs(file_thoughts) do
		nvim.annotate(bufnr, value.line_number)
	end
end

M.capture = function()
	local Input = require("nui.input")
	local event = require("nui.utils.autocmd").event
	local config = require("thought-flow.config")
	local repo = require("thought-flow.repo")

	local thought_line_number = vim.api.nvim_win_get_cursor(0)[1]
	local thought_file = vim.api.nvim_buf_get_name(0)
	local thought_line_content = vim.api.nvim_buf_get_lines(0, thought_line_number - 1, thought_line_number, false)[1]
	local thought_now = os.date()
	local input = Input({
		position = "50%",
		size = {
			width = 50,
		},
		border = {
			style = "single",
			text = {
				top = "[Thought Flow]",
				top_align = "center",
			},
		},
		win_options = {
			winhighlight = "Normal:Normal,FloatBorder:Normal",
		},
	}, {
		prompt = config.options.ui.prompt,
		default_value = "",
		on_submit = function(value)
			-- Validate input
			if not value or value:match("^%s*$") then
				vim.notify("Thought cannot be empty", vim.log.levels.WARN, { title = "thought-flow" })
				return
			end

			local added = repo.add(value, {
				line_number = thought_line_number,
				file = thought_file,
				content = thought_line_content,
				timestamp = thought_now,
			})
			if not added then
				return
			end

			M.annotate_buffer()
			invalidate_status_cache()
			refresh_tree()
		end,
	})

	-- mount/open the component
	input:mount()

	local is_quit = false
	input:on(event.QuitPre, function()
		is_quit = true
	end)
	-- unmount component when cursor leaves buffer
	input:on(event.BufLeave, function()
		if not is_quit then
			input:unmount()
		end
	end, { once = true })
end

M.review = function()
	require("neo-tree.command").execute({ source = "thought-flow", toggle = true })
end

M.remove_line = function()
	local repo = require("thought-flow.repo")

	local thought_line_number = vim.api.nvim_win_get_cursor(0)[1]
	local thought_file = vim.api.nvim_buf_get_name(0)
	repo.remove_thought(thought_file, thought_line_number)
	M.annotate_buffer()
	invalidate_status_cache()
	refresh_tree()
end

M.goto_next = function()
	local repo = require("thought-flow.repo")
	local nvim = require("thought-flow.nvim")
	local line = vim.api.nvim_win_get_cursor(0)[1]
	for _, data in ipairs(repo.get_sorted_for_file(vim.api.nvim_buf_get_name(0))) do
		if data.line_number > line then
			nvim.go_to_line(data.line_number)
			return
		end
	end
	vim.notify("No more thoughts in this file", vim.log.levels.INFO, { title = "thought-flow" })
end

M.goto_prev = function()
	local repo = require("thought-flow.repo")
	local nvim = require("thought-flow.nvim")
	local line = vim.api.nvim_win_get_cursor(0)[1]
	local thoughts = repo.get_sorted_for_file(vim.api.nvim_buf_get_name(0))
	for i = #thoughts, 1, -1 do
		local data = thoughts[i]
		if data.line_number < line then
			nvim.go_to_line(data.line_number)
			return
		end
	end
	vim.notify("No previous thoughts in this file", vim.log.levels.INFO, { title = "thought-flow" })
end

M.statistics = function()
	if _status_cache ~= nil then
		return _status_cache
	end

	local repo = require("thought-flow.repo")
	local thoughts = repo.get_all()
	local count = 0
	for _ in pairs(thoughts) do
		count = count + 1
	end

	_status_cache = {
		global_count = count,
	}
	return _status_cache
end

return M
