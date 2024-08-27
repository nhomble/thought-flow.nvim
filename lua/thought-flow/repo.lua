local version = "v1"
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
	local toWrite = {
		version = version,
		state = state,
	}
	if file then
		local json = config.options.json.encode(toWrite)
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
	local full = config.options.json.decode(content)
	if not full == nil and not full.state == nil then
		state = full.state
	end

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

M.remove_thought = function(file, line_number)
	-- remove from table
	for k, data in pairs(state) do
		if data.file == file and data.line_number == line_number then
			state[k] = nil
			break
		end
	end
	write()
end

return M
