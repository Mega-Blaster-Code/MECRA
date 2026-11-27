-- EVENT
-- serverSide.lua
-- by: MB 2026

local enet = require("enet")

local mecra = require("mecra")

local _M = {}

local config = mecra.config

local mchannel = mecra.core.transport.channel

local serialize = mecra.core.transport.serialize

local connection = mecra.core.connection

local router = mecra.core.transport.router

local function connect(self, manager, peer, rawdata)
    local client = self:newClient(peer)

    local payloadPackage = self:packRouter()
    local channelPackage = self:packChannel()

    self:_send(client, mecra.payloadTypes.handshake, {
		payloadConfig = payloadPackage,
		channelConfig = channelPackage,
	})

    manager:call("connect", self, client)

    return true, nil
end

local function disconnect(self, manager, client, rawdata)
    manager:call("disconnect", self, client)

    self.connectionCount = self.connectionCount - 1
    local index = client.connection:index()
	local id = client.connection:id()

    self.clientsByIndex[index] = nil
	self.clientsById[id] = nil

    return true, nil
end

local function receive(self, manager, client, rawdata, channel)
    local mcha = mchannel.getMchaByIndex(self, channel)

    local info, err = serialize.unserialize(mcha, rawdata)
    if err then
        return false, err
    end

    local _type, data = info.type, info.data
    local sucess, err = router.dispatch(self, _type, client, data)
	if not sucess then
		return false, err
	end

    return true, nil
end

function _M.service(self, manager)

    local timeout = config.get("timeout_service")

    while true do
        local client, channel, mcha

        local event = self.host:service(timeout)
        if not event then
            break
        end

        local _type, peer, rawdata, channel = event.type, event.peer, event.data, event.channel

        if _type == "connect" then
            local sucess, err = connect(self, manager, peer, rawdata)
            if not sucess then
                manager:error(err, mecra.errorLevels.error)
            end
            goto continue_service
        end

        client = self:getClientByIndex(peer:index())

        if _type == "disconnect" then
            local sucess, err = disconnect(self, manager, client, rawdata)
            if not sucess then
                manager:error(err, mecra.errorLevels.error)
            end
            goto continue_service
        end

        if _type == "receive" then
            local sucess, err = receive(self, manager, client, rawdata, channel)
            if not sucess then
                manager:error(err, mecra.errorLevels.error)
            end
            goto continue_service
        end

        ::continue_service::
    end
end

return _M
