-- ATTACH
-- attacher.lua
-- by: MB 2026
-- attaches it self to a SOC and registers callbacks. the manager pushes to the calls to queue stack.
local _M = {}

local unpack = table.unpack or unpack

local function f()

end

local attacher = {}
attacher.__index = attacher

function _M.new(soc)
    local selfa = setmetatable({}, attacher)

    selfa.att = {}
    selfa.queue = {}

    function soc:attach(name, func)
        selfa.att[name] = func
    end

    function soc:_pushCall(name, ...)
        selfa.queue[#selfa.queue + 1] = {
            name = name,
            args = {...}
        }
    end

    function soc:_isQueueEmpty()
        return #selfa.queue == 0
    end

    function soc:_popCall()
        local info = selfa.queue[#selfa.queue]
		selfa.queue[#selfa.queue] = nil
        local func = selfa.att[info.name]
        local args = info.args
        local nfunc = func or f
        nfunc(unpack(args))
        if not func then
            return false, "Attempt to call [" .. tostring(info.name) .. "] a empty callback"
        end
        return true, nil
    end

    return self
end

return _M
