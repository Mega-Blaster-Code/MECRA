local mecra = require("mecra")
local config = mecra.config
local hgeneral = mecra.hgeneral

local enet = require("enet")

local _M = {}

function _M.newServerHost(metatable, ip, port, name)
    port = port or config.get("default_port")
    name = name or "no name server " .. math.random()

    if not hgeneral.isValidIp(ip) then
        return nil, "invalid ip", nil
    end

    if not hgeneral.isValidPort(port) then
        return nil, "invalid port", nil
    end

    ip = hgeneral.normalizeIp(ip)

    local self = setmetatable({}, metatable)

    self.name = name
    self.ip = ip
    self.port = port

    -- needed by channel.lua
    self.mcha = {
        nameToIndex = {},
        indexToMcha = {}
    }

    -- needed by router.lua
    self.dynamicRouters = {}

    local address = hgeneral.formatAddress(ip, port)

    local channel_count = config.get("channel_count")
    local in_bandwith = config.get("in_bandwith")
    local out_bandwith = config.get("out_bandwith")

    local max_peer_count = config.get("max_peer_count")

    self.channel_count = channel_count
    self.in_bandwith = in_bandwith
    self.out_bandwith = out_bandwith
    self.max_peer_count = max_peer_count

    local host, err = enet.host_create(address, max_peer_count, channel_count, in_bandwith, out_bandwith)

    return host, err, self
end

function _M.setClientConnect(self, ip, port)
	port = port or config.get("default_port")

    if not hgeneral.isValidIp(ip) then
        return nil, "invalid ip", nil
    end

    if not hgeneral.isValidPort(port) then
        return nil, "invalid port", nil
    end

    ip = hgeneral.normalizeIp(ip)
	self.address = hgeneral.formatAddress(ip, port)
	self.ip = ip
    self.port = port
end

function _M.newClientHost(metatable, ip, port, name)
    name = name or "no name client " .. math.random()
    local self = setmetatable({}, metatable)

	self.name = name

	_M.setClientConnect(self, ip, port)

    -- needed by channel.lua
    self.mcha = {
        nameToIndex = {},
        indexToMcha = {}
    }

    -- needed by router.lua
    self.dynamicRouters = {}

    local channel_count = config.get("channel_count")
    local in_bandwith = config.get("in_bandwith")
    local out_bandwith = config.get("out_bandwith")

    local max_peer_count = config.get("max_peer_count")

    self.channel_count = channel_count
    self.in_bandwith = in_bandwith
    self.out_bandwith = out_bandwith
    self.max_peer_count = max_peer_count

    local host, err = enet.host_create(nil, nil, channel_count, in_bandwith, out_bandwith)

    return host, err, self
end

return _M
