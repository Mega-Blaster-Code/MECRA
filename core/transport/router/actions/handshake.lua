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
	return true, nil
end

local function server(self, client, data)
	return true, nil
end

local function handshake(soc, from, data)
    if soc._CLIENT then
		print("client side handshake")
		-- info about server channels
		return client(soc, from, data)
    end
	if soc._SERVER then
		print("client side handshake")

		return server(soc, from, data)
    end
	return true, nil
end

return handshake
