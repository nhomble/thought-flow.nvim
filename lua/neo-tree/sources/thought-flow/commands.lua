local cc = require("neo-tree.sources.common.commands")
local manager = require("neo-tree.sources.manager")
local Popup = require("nui.popup")

local M = {}

local function refresh()
	manager.refresh("thought-flow")
end

M.open = function(state)
	local node = state.tree:get_node()
	if node == nil then
		return
	end

	if node.type ~= "thought" then
		cc.toggle_node(state)
		return
	end

	if node.extra.is_orphaned then
		vim.notify("Cannot navigate: file or line no longer exists", vim.log.levels.WARN, { title = "thought-flow" })
		return
	end

	local utils = require("neo-tree.utils")
	local winid = utils.get_appropriate_window(state)
	vim.api.nvim_set_current_win(winid)

	local nvim = require("thought-flow.nvim")
	nvim.open_file_at_line(node.extra.thought_flow.file, node.extra.thought_flow.line_number)
end

M.delete_thought = function(state)
	local node = state.tree:get_node()
	if node == nil or node.type ~= "thought" then
		return
	end

	local repo = require("thought-flow.repo")
	local nvim = require("thought-flow.nvim")
	local thought_flow = require("thought-flow")

	repo.remove(node.extra.original_text)

	local target_bufnr = nvim.find_existing_buffer(node.extra.thought_flow.file)
	if target_bufnr then
		thought_flow.annotate_buffer(target_bufnr)
	end
	thought_flow.invalidate_status_cache()
	refresh()
end

M.show_full_text = function(state)
	local node = state.tree:get_node()
	if node == nil or node.type ~= "thought" then
		return
	end

	local full_text = node.extra.original_text
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

	local popup_height = math.max(3, math.min(#wrapped_lines + 2, 20))

	local full_text_popup = Popup({
		enter = true,
		focusable = true,
		zindex = 100,
		position = "50%",
		size = { width = "60%", height = popup_height },
		border = {
			style = "rounded",
			text = { top = " Full Thought ", top_align = "center" },
		},
	})

	full_text_popup:mount()
	vim.api.nvim_buf_set_lines(full_text_popup.bufnr, 0, -1, false, wrapped_lines)

	for _, key in ipairs({ "q", "<Esc>" }) do
		vim.api.nvim_buf_set_keymap(full_text_popup.bufnr, "n", key, "", {
			noremap = true,
			callback = function()
				full_text_popup:unmount()
			end,
		})
	end
end

cc._add_common_commands(M)

-- Node ids in this source are real file paths, but they are not real
-- filesystem entries to mutate — strip every common command that would
-- touch disk (add/rename/copy/move/delete/trash/git/...).
local disk_mutating_commands = {
	"add",
	"add_directory",
	"copy",
	"copy_to_clipboard",
	"copy_to_clipboard_visual",
	"cut_to_clipboard",
	"cut_to_clipboard_visual",
	"paste_from_clipboard",
	"clear_clipboard",
	"move",
	"rename",
	"rename_basename",
	"delete",
	"delete_visual",
	"trash",
	"trash_visual",
	"restore_from_trash",
	"restore_from_trash_visual",
	"undo",
	"git_add_file",
	"git_unstage_file",
	"git_toggle_file_stage",
	"git_add_all",
	"git_commit",
	"git_commit_and_push",
	"git_pull",
	"git_push",
	"git_undo_last_commit",
	"git_revert_file",
}
for _, name in ipairs(disk_mutating_commands) do
	M[name] = nil
end

return M
