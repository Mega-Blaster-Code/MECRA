-- channel.lua
-- by: MB 2025
--[[
channel

id
serialize -- if false then can only accept numbers or string

]] local _M = {}

local default_channel_config = {
    serialize = true,
    flags = "reliable"
}

-- sets up the configuration of the channels.
-- server side: done in the start of the script.
-- client side: server give on the first message the configuration of the channels.

function _M.setChannels(soc, opts) -- soc(server or client)
    opts = opts or {}
    local mchas = {} -- index to mcha
    local nameToMcha = {} -- name to index
    for i = 0, soc.channel_count - 1 do
        -- fills the mcha if empty
        local conf = opts[i] or default_channel_config
        local c = {}
        for k, v in pairs(conf) do
            c[k] = v
        end

        c.name = c.name or "channel " .. i
        c._channel = i

        -- check if name is repeated
        if nameToMcha[c.name] then
            return nil, "duplicated channel name " .. tostring(c.name)
        end

        nameToMcha[c.name] = i
        mchas[i] = c
    end

    soc.mcha.nameToIndex = nameToMcha
    soc.mcha.indexToMcha = mchas

    return true, nil
end

function _M.getMchaByIndex(soc, i)
    return soc.mcha.indexToMcha[i]
end

function _M.getMchaByName(soc, name)
    local index = soc.mcha.nameToIndex[name]
    return _M.getMchaByIndex(soc, index)
end

return _M
