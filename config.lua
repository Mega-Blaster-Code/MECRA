local _M = {}

local defaults_config = {
	default_port = 7070,
	channel_count = 8,

	max_peer_count = 64,
	
	in_bandwith = -1,
	out_bandwidth = -1,

	timeout_service = 0,

	timeout_try = 2,
	timeout_min = 1000,
	timeout_max = 3000,
}

local config = {}

function _M.set(opts)
	for name, value in pairs(opts) do
		if not (defaults_config[name] or type(value) == type(defaults_config[name])) then
			return nil, "invalid config " .. tostring(name)
		end
		config[name] = value
	end
	return true, nil
end

function _M.get(name)
	return config[name]
end

_M.set(defaults_config)

return _M