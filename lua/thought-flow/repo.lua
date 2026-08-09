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
		config.options.notifications.error("Unable to open file for writing: " .. err)
	end
end

local read = function()
	local file, err = io.open(config.options.path, "r") -- Open file in read mode
	if not file then
		config.options.notifications.error("Unable to open file for reading: " .. err)
		return
	end

	local content = file:read("*a") -- Read the entire file
	file:close() -- Close the file
	local full = config.options.json.decode(content)
	if full ~= nil and full.state ~= nil then
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

---@return boolean success false if a different thought already uses this text
M.add = function(thought, data)
	if state[thought] ~= nil then
		config.options.notifications.error("A thought with this text already exists: " .. thought)
		return false
	end
	state[thought] = data
	write()
	return true
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
