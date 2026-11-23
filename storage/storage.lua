-- storage.lua
-- by: MB 2026
-- from "mew v0.1"
-- require ltab.lua or tab.dll
-- remaking of mesma(deprecated)


--[[

The storage system is designed to create a unified and standardized data storage framework
including data replication, which can be customized by a high-level user.
It allows for configurations such as setting fields to "read-only"
or defining a specific data type for a field, ensuring that it must always
adhere to that designated data type.

]]

local _M = {}

local storage = {}
storage.__index = storage

function _M.new()
	local self = setmetatable({}, storage)

	self.data = {}

	return self
end

function storage:store(name, value, opts)
	if self.data[name] then
		return false
	end
	opts = opts or {}

	self.data[name] = {
		value = value,
		opts = {
			read_only = opts.read_only == true, -- read-only by both server and client
			default_value = opts.default_value,
			type = opts.type or "any",
			public = opts.public or false, -- if the data can be viewed by the client (there is no guarantee that it can be modified)
			client_modifiable = opts.client_modifiable or false -- determines whether the client can modify the data
		},
	}
	return true
end

function storage:read(name)
	local field = self.data[name]
	if not field then
		return nil
	end
	return field.value
end

function storage:write(name, value)
	local field = self.data[name]
	if not field then
		return false, "no data"
	end

	-- refuse if value has a different type
	if field.opts.type ~= "any" and type(value) ~= field.opts.type then
		return false, "invalid type"
	end

	if field.opts.read_only then
		return false, "read only"
	end

	field.value = value

	return true
end

function storage:reset(name)
	local field = self.data[name]
	field.value = field.opts.default_value
end

return _M