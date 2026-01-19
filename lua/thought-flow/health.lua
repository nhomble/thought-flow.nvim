local M = {}

M.check = function()
	vim.health.start("thought-flow.nvim")

	-- Check for nui.nvim dependency
	local ok_nui, _ = pcall(require, "nui.input")
	if ok_nui then
		vim.health.ok("nui.nvim is installed")
	else
		vim.health.error("nui.nvim is not installed", {
			"Install nui.nvim with your plugin manager",
			"Example: { 'MunifTanjim/nui.nvim' }",
		})
	end

	-- Check state file
	local config = require("thought-flow.config")
	local state_path = config.options.path
	local stat = vim.loop.fs_stat(state_path)

	if stat and stat.type == "file" then
		vim.health.ok("State file exists at " .. state_path)

		-- Try to read and parse state file
		local file = io.open(state_path, "r")
		if file then
			local content = file:read("*a")
			file:close()

			local ok_decode, decoded = pcall(config.options.json.decode, content)
			if ok_decode and decoded then
				local thought_count = 0
				if decoded.state then
					for _ in pairs(decoded.state) do
						thought_count = thought_count + 1
					end
				end
				vim.health.info("State file contains " .. thought_count .. " thought(s)")
			else
				vim.health.warn("State file exists but could not be parsed", {
					"File may be corrupted",
					"Consider backing up and running :ThoughtFlowClear to reset",
				})
			end
		else
			vim.health.warn("State file exists but could not be read")
		end
	else
		vim.health.info("State file not yet created (will be created on first use)")
	end
end

return M
