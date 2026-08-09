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
	vim.api.nvim_create_user_command("ThoughtFlowShow", M.show_thought, {
		desc = "Show the thought on the current line",
	})
	vim.api.nvim_create_user_command("ThoughtFlowHelp", M.show_help, {
		desc = "Show thought-flow keymap help",
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

local help_popup = nil

local function close_help()
	if help_popup then
		help_popup:unmount()
		help_popup = nil
	end
end

M.show_help = function()
	if help_popup then
		close_help()
		return
	end

	local entries = {
		{ cmd = "ThoughtFlowCapture", desc = "Capture a thought at cursor" },
		{ cmd = "ThoughtFlowReview", desc = "Toggle the thoughts neo-tree" },
		{ cmd = "ThoughtFlowNext", desc = "Next thought in file" },
		{ cmd = "ThoughtFlowPrev", desc = "Previous thought in file" },
		{ cmd = "ThoughtFlowShow", desc = "Show thought on this line" },
		{ cmd = "ThoughtFlowRemoveLine", desc = "Remove thought on this line" },
		{ cmd = "ThoughtFlowClear", desc = "Clear all thoughts" },
		{ cmd = "ThoughtFlowHelp", desc = "This help" },
	}

	local max_cmd_width = 0
	for _, e in ipairs(entries) do
		max_cmd_width = math.max(max_cmd_width, #e.cmd)
	end

	local lines = { "" }
	for _, e in ipairs(entries) do
		local padding = string.rep(" ", max_cmd_width - #e.cmd + 3)
		table.insert(lines, "  :" .. e.cmd .. padding .. e.desc)
	end
	table.insert(lines, "")

	local max_line_width = 0
	for _, line in ipairs(lines) do
		max_line_width = math.max(max_line_width, #line)
	end

	local Popup = require("nui.popup")
	help_popup = Popup({
		position = "50%",
		size = { width = math.max(max_line_width + 2, 30), height = #lines },
		border = {
			style = "rounded",
			text = { top = " Thought Flow Keymaps ", top_align = "center" },
		},
		buf_options = {
			modifiable = false,
			buftype = "nofile",
		},
	})

	help_popup:mount()

	local buf = help_popup.bufnr
	vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.api.nvim_set_option_value("modifiable", false, { buf = buf })

	local map_opts = { noremap = true, nowait = true }
	help_popup:map("n", "?", close_help, map_opts)
	help_popup:map("n", "q", close_help, map_opts)
	help_popup:map("n", "<Esc>", close_help, map_opts)
end

local editor_seq = 0

M.open_thought_editor = function(original_text, thought_data)
	local repo = require("thought-flow.repo")
	local nvim = require("thought-flow.nvim")

	local buf = vim.api.nvim_create_buf(false, true)
	vim.bo[buf].buftype = "acwrite"
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].swapfile = false
	vim.bo[buf].filetype = "markdown"
	vim.bo[buf].modifiable = true

	local base_name = "thought-flow://" .. thought_data.file .. ":" .. thought_data.line_number
	if not pcall(vim.api.nvim_buf_set_name, buf, base_name) then
		editor_seq = editor_seq + 1
		pcall(vim.api.nvim_buf_set_name, buf, base_name .. "#" .. editor_seq)
	end

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(original_text, "\n", { plain = true }))
	vim.bo[buf].modified = false

	vim.cmd("botright 6split")
	vim.api.nvim_win_set_buf(0, buf)
	vim.wo.winfixheight = true

	vim.keymap.set("n", "q", function()
		vim.bo[buf].modified = false
		vim.cmd("close")
	end, { buffer = buf, nowait = true })

	local current_key = original_text
	vim.api.nvim_create_autocmd("BufWriteCmd", {
		buffer = buf,
		callback = function()
			local new_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
			while #new_lines > 1 and new_lines[#new_lines]:match("^%s*$") do
				table.remove(new_lines)
			end

			if #new_lines > 1 then
				vim.notify("Thought must be a single line", vim.log.levels.WARN, { title = "thought-flow" })
				return
			end

			local new_text = (new_lines[1] or ""):gsub("^%s+", ""):gsub("%s+$", "")
			if new_text == "" then
				vim.notify("Thought cannot be empty", vim.log.levels.WARN, { title = "thought-flow" })
				return
			end

			if new_text ~= current_key then
				if not repo.add(new_text, thought_data) then
					return
				end
				repo.remove(current_key)
				current_key = new_text
			end

			vim.bo[buf].modified = false

			local target_bufnr = nvim.find_existing_buffer(thought_data.file)
			if target_bufnr then
				M.annotate_buffer(target_bufnr)
			end
			invalidate_status_cache()
			refresh_tree()
			vim.notify("Thought updated", vim.log.levels.INFO, { title = "thought-flow" })
		end,
	})
end

M.show_thought = function()
	local repo = require("thought-flow.repo")
	local file = vim.api.nvim_buf_get_name(0)
	local line = vim.api.nvim_win_get_cursor(0)[1]

	local thoughts_here = {}
	for thought_text, data in pairs(repo.find_thoughts_for_file(file)) do
		if data.line_number == line then
			table.insert(thoughts_here, thought_text)
		end
	end

	if #thoughts_here == 0 then
		vim.notify("No thought on this line", vim.log.levels.INFO, { title = "thought-flow" })
		return
	end

	table.sort(thoughts_here)
	local node_id = file .. "::" .. thoughts_here[1]

	-- Not passed as `reveal_file`: neo-tree normalizes that as a real
	-- filesystem path (e.g. collapsing "//" and trailing "/"), which can
	-- mangle a thought's id if its text contains those characters. Focus
	-- the node ourselves once the window/tree is ready instead.
	require("neo-tree.command").execute({ source = "thought-flow", action = "focus" })
	vim.schedule(function()
		local manager = require("neo-tree.sources.manager")
		local renderer = require("neo-tree.ui.renderer")
		local state = manager.get_state("thought-flow")
		if state then
			renderer.focus_node(state, node_id, false)
		end
	end)
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
