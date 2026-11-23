-- TRANSPORT
-- serialize.lua
-- by: MB 2026

local _M = {}

local mecra = require("mecra")

local ltab = mecra.core.transport.ltab

function _M.unserialize(mcha, rawdata)
    local isSerialized = mcha.serialize

	if not isSerialized then
		local type = rawdata:byte(1, 1)
		rawdata = rawdata:sub(2)
		return {data = rawdata, type = type}, nil
	end

	local data, err_info = ltab.unpack(rawdata)

	if type(data) ~= "table" and type(err_info) ~= "string"  then
		return nil, "Invalid data type. " .. type(data)
	end

	if type(err_info) == "string" then
		return nil, err_info
	end

	local _type = data.type
	local ddata = data.data

	return {
		data = ddata,
		type = _type,
	}, nil
end

function _M.serialize(mcha, _type, data)
	local isSerialized = mcha.serialize

	if not isSerialized then
		return string.char(_type) .. data, nil
	end

	local rawdata, err = ltab.pack({data = data, type = _type})

	return rawdata, err
end

return _M