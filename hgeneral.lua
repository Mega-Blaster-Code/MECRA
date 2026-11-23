-- HGENERAL
-- hgeneral.lua
-- by: MB 2026

local mecra = require("mecra")

local enet = require("enet")

local config = mecra.config

local _M = {}

function _M.isInteger(n)
    return type(n) == "number" and n == n and n % 1 == 0
end

local function l_trim(s)
    return (s:match("^%s*(.-)%s*$"))
end

function _M.hash256(value)
    return love.data.hash("string", "sha256", value)
end

function _M.isValidIp(ip, lenient)
    if type(ip) ~= "string" then
        return nil
    end
	if ip == "*" then
		return true
	end
    local a, b, c, d = ip:match("^(%d+)%.(%d+)%.(%d+)%.(%d+)$")
    if not a then
        return nil
    end
    local parts = {a, b, c, d}
    local out = {}
    for i = 1, 4 do
        local s = parts[i]
        if #s > 3 then
            return nil
        end
        if not lenient and #s > 1 and s:sub(1, 1) == "0" then
            return nil
        end
        local n = tonumber(s)
        if not n or n > 255 then
            return nil
        end
        out[i] = n
    end
    return out
end

function _M.normalizeIp(s)
	if s == "*" then
		return s
	end
    local o = _M.isValidIp(s, true)
    if not o then
        return nil
    end
    return string.format("%d.%d.%d.%d", o[1], o[2], o[3], o[4])
end

function _M.isValidPort(port)
    if port < 0 or port > 65535 then
        return false
    end
    return _M.isInteger(port)
end

function _M.getIpValues(ip)
    if not _M.isValidIp(ip) then
        return nil
    end
    local a, b, c, d = ip:match("^(%d+)%.(%d+)%.(%d+)%.(%d+)$")
    return {a, b, c, d}
end

function _M.parseAddress(address)
    if type(address) ~= "string" then
        return nil, "address must be a string"
    end
    local ip, port = address:match("^(%d+%.%d+%.%d+%.%d+):(%d+)$")
    if not ip then
        return nil, "invalid address format"
    end
    if not _M.isValidIp(ip) then
        return nil, "ip invalid"
    end
    port = tonumber(port)
    if not _M.isValidPort(port) then
        return nil, "port invalid"
    end
    return ip, port
end

function _M.formatAddress(ip, port)
    if type(ip) ~= "string" then
        return nil, "ip must be a string"
    end
    if type(port) ~= "number" then
        return nil, "port must be a number"
    end
    if not _M.isValidIp(ip) then
        return nil, "ip invalid"
    end
    if not _M.isValidPort(port) then
        return nil, "port invalid"
    end
    return string.format("%s:%d", ip, port)
end

return _M
