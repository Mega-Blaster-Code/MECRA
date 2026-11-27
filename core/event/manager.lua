-- EVENT
-- manager.lua
-- by: MB 2026

local mecra = require("mecra")

local _M = {}

local serverSide = mecra.core.event.serverSide
local clientSide = mecra.core.event.clientSide

local att = mecra.core.event.attach

local manager = {}
manager.__index = manager

local f = function(soc, client)

end

-- The manager is a simple system designed to abstract ENet’s event system.
-- The manager determines whether the SOC (server or client) is a client or a server and calls the corresponding function.
function _M.new(soc)
    local self = setmetatable({}, manager)

	self.soc = soc
	
    self.callbacks = {
		connect = f,
        disconnect = f
    }
	
    self.errors = {}

	self.attacher = att.new(soc)

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

local function attachFuncs(soc)
	if soc:_isQueueEmpty() then
		return true, nil
	end
	local errors = {}
	while not soc:_isQueueEmpty() do
		local result, err = soc:_popCall()
		if not result then
			errors[#errors + 1] = {
				err = err,
				level = mecra.errorLevels.error
			}
		end
	end
	if #errors == 0 then
		return nil
	end
	return errors
end

function manager:service() -- soc (server or client)
	local soc = self.soc
	local _, errs = attachFuncs(soc)
	if errs then
		print(inspect(errs))
	end
	
    if soc._SERVER then
        return serverSide.service(soc, self)
    end
    if soc._CLIENT then
        return clientSide.service(soc, self)
    end
end

return _M
