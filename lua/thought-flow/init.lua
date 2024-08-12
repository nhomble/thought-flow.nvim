local M = {}

M.init = function()
	require("thought-flow.repo").init()
end

M.setup = function(options)
	require("thought-flow.config").configure(options)
end

M.capture = function()
	local config = require("thought-flow.config")
	local Input = require("nui.input")
	local event = require("nui.utils.autocmd").event
	local repo = require("thought-flow.repo")

	local thought_line_number = vim.api.nvim_win_get_cursor(0)[1]
	local thought_file = vim.api.nvim_buf_get_name(0)
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
				timestamp = thought_now,
			})
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
	local event = require("nui.utils.autocmd").event
	local repo = require("thought-flow.repo")
	local nvim = require("thought-flow.nvim")

	local json = repo.get_all()
	local lines = {}
	for key in pairs(json) do
		local item = Menu.item(key, {
			thought_flow = json[key],
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
			repo.remove(item.text)
		end,
		on_submit = function(item)
			local file = item["thought_flow"].file
			local ln = item["thought_flow"].line_number
			print("" .. file .. " " .. ln)
			nvim.open_file_at_line(file, ln)
		end,
	})
	menu:mount()
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

M.init()
return M
