-- ACTIONS
-- handshake.lua
-- by: MB 2026

local mecra = require("mecra")

local router = require(mecra._cur_path .. ".router")

local mchannel = mecra.core.transport.channel

local function client(self, server, data)
	return true, nil
end

local function server(self, client, data)
	return true, nil
end

local function storage(soc, from, data)
    if soc._CLIENT then
		return client(soc, from, data)
    end
	if soc._SERVER then

		return server(soc, from, data)
    end
	return true, nil
end

return storage
