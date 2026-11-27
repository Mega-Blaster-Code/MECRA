-- storage.lua
-- by: MB 2026


--[[

The storage system is designed to create a unified and standardized data storage framework
including data replication, which can be customized by the server and only the server.
It allows for configurations such as setting fields to "read-only"
or defining a specific data type for a field, ensuring that it must always
adhere to that designated data type.

]]

local mecra = require("mecra")

local recorder = mecra.storage.recorder

local _M = {}

local storage = {}
storage.__index = storage

function _M.new(record)
	local self = setmetatable({}, storage)

	if record then
		recorder.record(self, 100)
	end

	self.data = {}

	return self
end

function storage:_validateWrite(name, value)
	local field = self.data[name]
	if not field then
		return false
	end

	-- refuse if value has a different type
	if field.opts.type ~= "any" and type(value) ~= field.opts.type then
		return false
	end

	if field.opts.read_only then
		return false
	end

	return true
end

function storage:_validateRead(name)
	if not self.data[name] then
		return false
	end
	return true
end

function storage:_log(_type, name, value, opts)
	if not self.recorder then
		return
	end
	self.recorder:record(_type, name, value, opts)
end

-- this only expects simple values
-- it was not designed for tables but they are alowed

-- if table is used then calling reset will do nothing, because default_value and value are a pointer to the same table
-- so modifing one will change the other
-- there is also no check for values inside the table, the system can only verify that the value is a table
function storage:store(name, value, opts)
	if self.data[name] then
		return false
	end
	opts = opts or {}

	self:_log("create", name, value, opts)

	self.data[name] = {
		value = value,
		opts = {
			read_only = opts.read_only == true, -- read-only by both server and client
			default_value = opts.default_value,
			type = opts.type or "any",
			public = opts.public or false, -- if the data can be viewed by the client
		},
	}
	return true
end

function storage:isReadOnly(name)
	if not self:_validateRead(name) then
		return nil
	end
	local field = self.data[name]
	return field.read_only
end

function storage:type(name)
	if not self:_validateRead(name) then
		return nil
	end
	local field = self.data[name]
	return field.type
end

function storage:isPublic(name)
	if not self:_validateRead(name) then
		return nil
	end
	local field = self.data[name]
	return field.public
end

function storage:getDefaultValue(name)
	if not self:_validateRead(name) then
		return nil
	end
	local field = self.data[name]
	return field.default_value
end

function storage:delete(name)
	if not self:_validateRead(name) then
		return false
	end
	if self:isReadOnly(name) then
		return false
	end
	self:_log("delete", name)
	self.data[name] = nil
end

function storage:read(name)
	if not self:_validateRead(name) then
		return nil
	end
	local field = self.data[name]
	return field.value
end

function storage:write(name, value)
	if not self:_validateWrite(name, value) then
		return false
	end

	self:_log("write", name, value)

	local field = self.data[name]
	field.value = value

	return true
end

function storage:reset(name)
	if not self:_validateWrite(name) then
		return false
	end

	self:_log("reset", name)

	local field = self.data[name]
	field.value = field.opts.default_value
end

return _M