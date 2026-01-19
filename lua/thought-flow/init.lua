local M = {}

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
		desc = "Capture a thought at the current cursor position"
	})
	vim.api.nvim_create_user_command("ThoughtFlowReview", M.review, {
		desc = "Review all captured thoughts"
	})
	vim.api.nvim_create_user_command("ThoughtFlowClear", M.clear, {
		desc = "Clear all thoughts"
	})
	vim.api.nvim_create_user_command("ThoughtFlowRemoveLine", M.remove_line, {
		desc = "Remove thought at current cursor line"
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
	for _key, value in pairs(file_thoughts) do
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
			repo.add(value, {
				line_number = thought_line_number,
				file = thought_file,
				content = thought_line_content,
				timestamp = thought_now,
			})
			M.annotate_buffer()
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
	local Menu = require("thought-flow.nui-menu-extended")
	local Popup = require("nui.popup")
	local event = require("nui.utils.autocmd").event
	local repo = require("thought-flow.repo")
	local nvim = require("thought-flow.nvim")
	local config = require("thought-flow.config")

	local bufnr = vim.api.nvim_get_current_buf()
	local json = repo.get_all()
	local lines = {}

	-- Helper to truncate text
	local function truncate_text(text, max_width)
		max_width = max_width or 50  -- Default if not configured
		if #text <= max_width then
			return text
		end
		return text:sub(1, max_width - 3) .. "..."
	end

	-- Helper to check if thought is orphaned
	local function is_orphaned(thought_data)
		local file = thought_data.file
		local line_number = thought_data.line_number

		-- Check if file exists
		local stat = vim.loop.fs_stat(file)
		if not stat or stat.type ~= "file" then
			return true
		end

		-- Check if line number is valid
		local ok, bufnr = pcall(vim.fn.bufadd, file)
		if not ok then
			return true
		end

		pcall(vim.fn.bufload, bufnr)
		local line_count = vim.api.nvim_buf_line_count(bufnr)

		return line_number > line_count
	end

	for key in pairs(json) do
		local thought_data = json[key]
		local orphaned = is_orphaned(thought_data)
		local indicator = orphaned and (config.options.orphaned.indicator or "[!] ") or ""
		local display_text = indicator .. truncate_text(key, config.options.ui.max_thought_display_width)

		local item = Menu.item(display_text, {
			thought_flow = thought_data,
			original_text = key,
			is_orphaned = orphaned,
		})
		table.insert(lines, item)
	end
	local popup_options = {
		position = "50%",
		size = {
			width = 50,
		},

		border = {
			style = "rounded",
			text = {
				top = "[Find thought]",
				top_align = "center",
			},
		},
		win_options = {
			winhighlight = "Normal:Normal",
		},
	}

	local menu = Menu(popup_options, {
		lines = lines,
		max_width = 20,
		keymap = {
			focus_next = { "j", "<Down>", "<Tab>" },
			focus_prev = { "k", "<Up>", "<S-Tab>" },
			close = { "<Esc>", "<C-c>" },
			submit = { "<CR>", "<Space>" },
		},
		on_delete = function(item)
			if item == nil then
				return
			end
			repo.remove(item.original_text or item.text)
			M.annotate_buffer(bufnr)
		end,
		on_submit = function(item)
			if item == nil then
				return
			end

			-- Check if thought is orphaned
			if item.is_orphaned then
				vim.notify("Cannot navigate: file or line no longer exists", vim.log.levels.WARN, { title = "thought-flow" })
				return
			end

			local file = item["thought_flow"].file
			local ln = item["thought_flow"].line_number
			nvim.open_file_at_line(file, ln)
		end,
	})
	menu:mount()

	-- Add Space to show full thought text
	vim.api.nvim_buf_set_keymap(menu.bufnr, "n", "<Space>", "", {
		noremap = true,
		nowait = true,
		callback = function()
			local item = menu.tree:get_node()
			if not item then
				return
			end

			local full_text = item.original_text or item.text

			-- Pre-calculate wrapped lines to determine height
			local popup_width = math.floor(vim.o.columns * 0.6)
			local wrapped_lines = {}
			local current_line = ""

			for word in full_text:gmatch("%S+") do
				if #current_line + #word + 1 <= popup_width - 4 then
					current_line = current_line .. (current_line == "" and "" or " ") .. word
				else
					table.insert(wrapped_lines, current_line)
					current_line = word
				end
			end
			if current_line ~= "" then
				table.insert(wrapped_lines, current_line)
			end

			if #wrapped_lines == 0 then
				wrapped_lines = { full_text }
			end

			-- Dynamic height based on content (min 3, max 20)
			local popup_height = math.max(3, math.min(#wrapped_lines + 2, 20))

			-- Show full thought in popup
			local full_text_popup = Popup({
				enter = true,
				focusable = true,
				zindex = 100,
				position = "50%",
				size = {
					width = "60%",
					height = popup_height,
				},
				border = {
					style = "rounded",
					text = {
						top = " Full Thought ",
						top_align = "center",
					},
				},
			})

			full_text_popup:mount()
			vim.api.nvim_buf_set_lines(full_text_popup.bufnr, 0, -1, false, wrapped_lines)

			-- Close with q or Esc
			vim.api.nvim_buf_set_keymap(full_text_popup.bufnr, "n", "q", "", {
				noremap = true,
				callback = function()
					full_text_popup:unmount()
				end,
			})

			vim.api.nvim_buf_set_keymap(full_text_popup.bufnr, "n", "<Esc>", "", {
				noremap = true,
				callback = function()
					full_text_popup:unmount()
				end,
			})
		end,
	})

	local is_quit = false
	menu:on(event.QuitPre, function()
		is_quit = true
	end)
	-- unmount component when cursor leaves buffer
	menu:on(event.BufLeave, function()
		if not is_quit then
			menu:unmount()
		end
	end, { once = true })
end

M.remove_line = function()
	local repo = require("thought-flow.repo")

	local thought_line_number = vim.api.nvim_win_get_cursor(0)[1]
	local thought_file = vim.api.nvim_buf_get_name(0)
	repo.remove_thought(thought_file, thought_line_number)
	M.annotate_buffer()
end

return M
