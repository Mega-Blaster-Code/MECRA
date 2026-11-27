-- storage.lua
-- by: MB 2026
--[[

the recorder register all the changes on a storage.
you can play the changes to a storage with the same data.
the recorder will verify the recording before playing it.
you can change the behaviur of the cheks to allow some warnings and fix them
if an edit is played but the storage don't have the data it will stop and won't commit the changes

]] local _M = {}

local love = love or {}
local data = love.data or {}
local compress = love.data.compress
local decompress = love.data.decompress

local function compress(data)
    if not compress then
        return {
            data = data,
            compressed = false
        }
    end
end

-- maxData is the maximun amount of changes to record.
-- if the changes is bigger then maxData then the changes will be packed with ltab and then compressed if love is being used.

_M.types = {
    create = 0,
    delete = 1,
    write = 2,
	reset = 3,
}

local recorder = {}
recorder.__index = recorder

function _M.record(storage, maxData)
    if storage.recorder then
        return nil, "storage already have a recorder"
    end

    local self = setmetatable({}, recorder)

	self.cchanges = {}
    self.changes = {}

    storage.recorder = self

    return self, nil
end

function recorder:record(_type, name, value, opts)
	local t = _M.types[_type]
	if not t then
		return false
	end

	local f = {
		type = t,
		name = name,
	}

	if t == _M.types.create then
		f.value = value
		f.opts = opts
	end

	if t == _M.types.write then
		f.value = value
	end

	self.changes[#self.changes +1 ] = f

end

return _M
