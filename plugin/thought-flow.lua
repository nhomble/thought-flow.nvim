-- Prevent double-loading
if vim.g.loaded_thought_flow then
	return
end
vim.g.loaded_thought_flow = 1

-- Plugin is initialized via setup() call in user's config
-- This file serves as the standard plugin entrypoint
