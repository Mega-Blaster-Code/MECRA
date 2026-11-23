-- manager.lua
local mecra = require("mecra")

local _M = {}

local serverSide = mecra.core.event.serverSide
local clientSide = mecra.core.event.clientSide

local manager = {}
manager.__index = manager

local f = function(soc, client)

end

-- The manager is a simple system designed to abstract ENet’s event system.
-- The manager determines whether the SOC (server or client) is a client or a server and calls the corresponding function.
function _M.new()
    local self = setmetatable({}, manager)

    self.callbacks = {
        connect = f,
        disconnect = f
    }

    self.errors = {}

    return self
end

function manager:call(name, ...)
    local f = self.callbacks[name]
    if not f then
        return nil
    end
    return f(...)
end

function manager:error(msg, level)
    self.errors[#self.errors + 1] = {
        msg = msg,
        level = level
    }
end

function manager:popError()
    return table.remove(self.errors, 1)
end

function manager:hadError()
    return #self.errors ~= 0
end

function manager:service(soc) -- soc (server or client)
    if soc._SERVER then
        return serverSide.service(soc, self)
    end
    if soc._CLIENT then
        return clientSide.service(soc, self)
    end
end

return _M
