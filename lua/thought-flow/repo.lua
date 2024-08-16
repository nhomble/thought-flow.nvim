local state = {}
local config = require("thought-flow.config")

local can_read = function()
	local f = io.open(config.options.path, "r")
	if f ~= nil then
		io.close(f)
		return true
	else
		return false
	end
end

local write = function()
	local file, err = io.open(config.options.path, "w")
	if file then
		local json = config.options.json.encode(state)
		file:write(json)
		file:close()
	else
		print("[Error] Unable to open file for writing: " .. err)
	end
end

local read = function()
	local file, err = io.open(config.options.path, "r") -- Open file in read mode
	if not file then
		print("[Error] opening file: " .. err)
		return
	end

	local content = file:read("*a") -- Read the entire file
	file:close() -- Close the file
	state = config.options.json.decode(content)

	return state
end

local M = {}

M.init = function()
	if not can_read() then
		write()
	else
		read()
	end
end

M.get_all = function()
	return state
end

M.add = function(thought, data)
	state[thought] = data
	write()
end

M.remove = function(thought)
	state[thought] = nil
	write()
end

M.clear = function()
	state = {}
	write()
end

M.find_thoughts_for_file = function(file)
	local result = {}
	for key, value in pairs(state) do
		if value.file == file then
			result[key] = value
		end
	end
	return result
end

return M
