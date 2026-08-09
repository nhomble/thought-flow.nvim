local highlights = require("neo-tree.ui.highlights")
local common = require("neo-tree.sources.common.components")

local M = {}

M.icon = function(component_config, node, state)
	local config = require("thought-flow.config")
	local padding = component_config.padding or " "

	if node.type == "directory" then
		local icon = node:is_expanded() and "\u{f07c}" or "\u{f07b}"
		return { text = icon .. padding, highlight = highlights.DIRECTORY_ICON }
	end

	local highlight = node.extra.is_orphaned and "ThoughtFlowOrphaned" or highlights.FILE_ICON
	return { text = config.options.annotations.text .. padding, highlight = highlight }
end

M.name = function(component_config, node, state)
	if node.type ~= "thought" then
		return { text = node.name, highlight = highlights.DIRECTORY_NAME }
	end

	local highlight = node.extra.is_orphaned and "ThoughtFlowOrphaned" or highlights.FILE_NAME
	return { text = node.name, highlight = highlight }
end

return vim.tbl_deep_extend("force", common, M)
