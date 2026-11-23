local _M = {}

_G.package.loaded[...] = _M

local mecra = require("mecra")

local path = mecra._cur_path

local defaults = {"handshake"}

local defaultRouterTypes = {}

for i, name in ipairs(defaults) do
    defaultRouterTypes[name] = {
        callback = require(path .. ".actions." .. name),
        name = name,
        type = i - 1
    }
end

local function f(soc, from, data)
    print("CALLBACK NOT SET", inspect(data))
end

function _M.setRouterConfig(soc, opts)
    opts = opts or {}

    local defaults = defaultRouterTypes
    local dynamicRouters = {}
    local defaultConfig = soc.defaultConfig or {}

    for name, config in pairs(defaults) do
        dynamicRouters[config.type] = {
            name = name,
            callback = config.callback,
            channel = 0,
            type = config.type
        }
    end

    local names = {}

    for name in pairs(opts) do
        if defaults[name] then
            return false, "Invalid router name: " .. name
        end

        names[#names + 1] = name
    end

    table.sort(names)

    local nextType = 8

    for _, name in ipairs(names) do
        local info = opts[name]
        local payloadConfig = defaultConfig[name] or {}

        local payloadType = info.type or nextType

        if not info.type then
            nextType = nextType + 1
        end

        dynamicRouters[payloadType] = {
            name = name,
            callback = info.callback or payloadConfig.callback or f,
            channel = info.channel or 0,
            type = payloadType
        }
    end

    soc.dynamicRouters = dynamicRouters

    return true
end

function _M.getRouterInfoByType(soc, _type)
    local pay = soc.dynamicRouters[_type]
    return pay
end

function _M.getRouterInfoByName(soc, name)
    for _type, info in pairs(soc.dynamicRouters) do
        if info.name == name then
            return info
        end
    end
    return nil
end

function _M.dispatch(soc, _type, ...)
	local payloadInfo = _M.getRouterInfoByType(soc, _type)
	if not payloadInfo then
		return false, "router"
	end
	return payloadInfo.callback(soc, ...)
end

return _M
