-- ACTIONS
-- handshake.lua
-- by: MB 2026

local mecra = require("mecra")

local router = require(mecra._cur_path .. ".router")

local mchannel = mecra.core.transport.channel

local function client(self, server, data)
	mchannel.setChannels(self, data.channelConfig)
	local payloadConfig = {}
	for name, info in pairs(data.payloadConfig) do
		if info.type >= 8 then
			payloadConfig[name] = info
		end
	end

	router.setRouterConfig(self, payloadConfig)

	if not self._handshake then
		self:_pushCall("onPlayerJoin", client)
	end
	self._handshake = true

	local id = self:getRouterId("handshake")
	self:_send(id, {
		ok = true,
		usingLove = love ~= nil and type(love) == "table",
		usingMgold = love ~= nil and type(love) == "table" and (love or {})._isMGOLD ~= nil
	})

	return true, nil
end

local function server(self, client, data)
	client.usingLove = data.usingLove == true
	client.usingMgold = data.usingMgold == true
	if not client._handshake then
		self:_pushCall("onPlayerJoin", client)
	end
	client._handshake = true
	return true, nil
end

local function handshake(soc, from, data)
    if soc._CLIENT then
		-- info about server channels
		return client(soc, from, data)
    end
	if soc._SERVER then

		return server(soc, from, data)
    end
	return true, nil
end

return handshake
