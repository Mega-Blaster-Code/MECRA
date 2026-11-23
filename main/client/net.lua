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

local client = {}
client.__index = client

function _M.new(ip, port, name)
    local host, err, self = henet.newClientHost(client, ip, port, name)

    if err then
        return nil, err
    end

    self._CLIENT = true

    self.host = host

    self.payloadConfig = {}
    self.defaultConfig = {}

    -- server storage config
    self.serverConfig = {}
    self.storage = storage.new()

    self.server = {
        connected = false
    }

    self.manager = manager.new()
    self.manager.callbacks.connect = function(self, server)
        print("client: connect", server)
    end

    self.manager.callbacks.disconnect = function(self, server)
        print("client: disconnet", inspect(server))
    end

    mchannel.setChannels(self)
    router.setRouterConfig(self)

    return self
end

function client:connect(ip, port)
    henet.setClientConnect(self, ip or self.ip, port or self.port)
    self.host:connect(self.address, self.channel_count)
end

-- defines the callback for router types
-- the server will receive the type and the data from the client
-- it will then look for it within the standard payloadTypes
-- if nothing is found, it will search within the dynamic payloadTypes
-- opts:
-- {chat = {callback = ...}}
-- this only sets the callback, channel is given by the server.
-- the callback is a function that receives (client: table, data: string)
do
    local function f()
    end

    function client:setRouterConfig(opts)
        for name, info in pairs(opts) do
            self.defaultConfig[name] = {
                callback = info.callback or f
            }
        end
    end
end

-- opts:
-- {chat = {callback = ..., channel = 0}}
function client:getRouterConfig(opts)
    -- TODO: e
end

function client:getRouterId(name)
    return (router.getRouterInfoByName(self, name) or {}).type
end

-- affter connect
function client:setServer(peer)
    local conn = connection.new(peer)
    local ip, port, _ = conn:getIpPort()
    self.server = {
        connected = true,
        connection = conn,
        ping = conn:getPing(),
        state = conn:getState(),
        address = conn:getAddress(),
        ip = ip,
        port = port
    }
end

function client:setStorageConfig()
    self.storage = storage.new()
    for key, opts in pairs(self.serverConfig) do
        self.storage:store(key, opts.value, opts)
    end
end

-- internal use only
function client:_send(_type, data)
    if not self.server.connected then
        return false, "not connected"
    end
    local payloadInfo = router.getRouterInfoByType(self, _type)

    local mcha = mchannel.getMchaByIndex(self, payloadInfo.channel)

    local rawdata, err = serialize.serialize(mcha, _type, data)
    if err then
        return false, err
    end

    self.server.connection:send(rawdata, mcha)
end

-- external use only
function client:send(_type, data)
    if not self.server.connected then
        return false, "not connected"
    end

    if _type < 4 then
        return false, "restricted router type " .. tostring(_type)
    end

    local sucess, result = self:_send(_type, data)

    return sucess, result
end

function client:update(dt)
    if not self.host then
        return
    end

    if self.server.connected then
        local conn = self.server.connection

        self.server.ping = conn:getPing()
        self.server.state = conn:getState()
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

function client:close()
    if not self.server.connected then
        return
    end
    self.server.connection:close()
end

return _M
