-- CORE
-- connection.lua
-- by: MB 2026

-- The connection is an abstraction of an ENet peer.
-- It hides the peer and exposes certain functions to the SOC (server or client).
local mecra = require("mecra")
local config = mecra.config
local hgeneral = mecra.hgeneral

local enet = require("enet")

local _M = {}

local connection = {}
connection.__index = connection

function _M.new(peer)
    local self = setmetatable({}, connection)

    local timeout_try = config.get("timeout_try")
    local timeout_max = config.get("timeout_max")
    local timeout_min = config.get("timeout_min")

    peer:timeout(timeout_try, timeout_max, timeout_min)

    self.peer = peer

    return self
end

function connection:id()
    return self.peer:connect_id()
end

function connection:index()
    return self.peer:index()
end

function connection:getPing()
    return self.peer:last_round_trip_time()
end

function connection:getState()
    return self.peer:state()
end

function connection:getAddress()
    return tostring(self.peer)
end

function connection:getIpPort()
    local address = self:getAddress()
    local ip, port = hgeneral.parseAddress(address)
    if not ip then
        return nil, nil, port -- port can also be error
    end
    return ip, port, nil
end

function connection:send(msg, mcha)
    local result = self.peer:send(msg, mcha.channel, mcha.flags)

    return result == 0, result
end

function connection:close(when)
    if when == "now" then
        self.peer:disconnect_now(0)
    else
        self.peer:disconnect(0)
    end
end

return _M
