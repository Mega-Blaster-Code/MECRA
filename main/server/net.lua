-- SERVER
-- net.lua
-- by: MB 2026
local mecra = require("mecra")

local config = mecra.config

local hgeneral = mecra.hgeneral

local storage = mecra.storage.storage

local router = mecra.core.transport.router

local henet = mecra.core.transport.henet

local mchannel = mecra.core.transport.channel

local serialize = mecra.core.transport.serialize

local connection = mecra.core.connection

local manager = mecra.core.event.manager

local _M = {}

local enet = require("enet")

local server = {}
server.__index = server

function _M.new(ip, port, name, password)
    local host, err, self = henet.newServerHost(server, ip, port, name, password)

    if err then
        return nil, err
    end

    self._SERVER = true

    self.host = host

    self.connectionCount = 0

    self.payloadConfig = {}

    -- default config of each client
    self.clientConfig = {}

    self.clientsByIndex = {}
	self.clientsById = {}

    self.globalStorage = storage.new()

    self.manager = manager.new()
    self.manager.callbacks.connect = function(self, client)
		print("server: connect", client)
    end

    self.manager.callbacks.disconnect = function(self, client)
        print("server: connect", client)
    end

    self:setChannels()

    return self
end

function server:getConnectionCount()
    return self.connectionCount
end

-- set the default local storage for each client
function server:setClientConfig(opts)
    for name, storOpts in pairs(opts) do
        self.clientConfig[name] = storOpts
    end
end

-- the firts channel is for internal use only
function server:setChannels(opts)
    opts = opts or {}
    for i, v in pairs(opts) do
        if i == 0 then
            return false, "Can't edit internal channel spec"
        end
    end
    return mchannel.setChannels(self, opts)
end

-- defines the callback for router types
-- the server will receive the type and the data from the client
-- it will then look for it within the standard payloadTypes
-- if nothing is found, it will search within the dynamic payloadTypes
-- opts:
-- {chat = {callback = ..., channel = 0}}
-- the callback is a function that receives (client: table, data: string)
function server:setRouterConfig(opts)
    for name, conf in pairs(opts) do
        if conf.channel == 0 then
            return false, "Router type can't use channel 0"
        end
    end
    return router.setRouterConfig(self, opts)
end

function server:getRouterId(name)
    return (router.getRouterInfoByName(self, name) or {}).type
end

-- returns a table with the types of router and what channels they use.
-- this is used to send the router types to the client.
function server:packRouter()
    local result = {}
    for k, v in pairs(self.dynamicRouters) do
        result[v.name] = {
            channel = v.channel,
            type = v.type
        }
    end
    return result
end

-- returns a table with the channels information.
function server:packChannel()
    local result = {}
    for k, v in pairs(self.mcha.indexToMcha) do
        result[k] = {
            serialize = v.serialize,
            flags = v.flags,
            name = v.name
        }
    end
    return result
end

function server:newClient(peer)
	local conn = connection.new(peer)
    local ip, port, _ = conn:getIpPort()

    local client = {
        connection = conn,
        ping = conn:getPing(),
        state = conn:getState(),
        address = conn:getAddress(),
        ip = ip,
        port = port
    }

    -- sets up the client local storage
    client.storage = storage.new()
    for key, opts in pairs(self.clientConfig) do
        client.storage:store(key, opts.value, opts)
    end

    self.connectionCount = self.connectionCount + 1
    self.clientsByIndex[client.connection:index()] = client
	self.clientsById[client.connection:id()] = client

    return client
end

function server:getClientByIndex(index)
    return self.clientsByIndex[index]
end

function server:getClientByConnectionId(id)
    return self.clientsById[id]
end

-- internal use only
function server:_send(client, _type, data)
    local payloadInfo = router.getRouterInfoByType(self, _type)

    local mcha = mchannel.getMchaByIndex(self, payloadInfo.channel)

    local rawdata, err = serialize.serialize(mcha, _type, data)
    if err then
        return false, err
    end

    client.connection:send(rawdata, mcha)
end

-- external use only
function server:send(client, _type, data)
    if _type < 4 then
        return false, "restricted router type " .. tostring(_type)
    end

    local sucess, result = self:_send(client, _type, data)

    return sucess, result
end

function server:update(dt)
    if not self.host then
        return
    end

	for k, client in pairs(self.clientsByIndex) do
		local conn = client.connection
		client.ping = conn:getPing()
		client.state = conn:getState()
	end

    local sucess, err = self.manager:service(self)
    if err then
        print("ERROR SERVICE", err)
    end
    if self.manager:hadError() then
        while self.manager:hadError() do
            print("ERROR SERVICE", inspect(self.manager:popError()))
        end
    end
end

return _M
