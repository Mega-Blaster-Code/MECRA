-- Modular Enet Comunication and Replication Architecture
-- MECRA

-- MECRA
-- init.lua
-- by: MB 2026

math.randomseed(os.time())

local path = ...

local _M = {
	_VERSION = "0.5",
	_LICENSE = require(path .. ".license")
}

_G.package.loaded[path] = _M
_M.path = path

-- internal use only
_M._cur_path = path

_M.errorLevels = {
    log = 0,
    warning = 1,
    error = 2
}

_M.payloadTypes = {
    handshake = 0,
    rawdata = 1
}

_M._cur_path = path .. ""
_M.config = require(path .. ".config")
_M.hgeneral = require(path .. ".hgeneral")

-- === CORE
_M._cur_path = path .. ".core"

_M.core = {}

-- === transport
_M._cur_path = path .. ".core.transport"

_M.core.transport = {}
_M.core.transport.ltab = require(_M._cur_path .. ".ltab")
_M.core.transport.channel = require(_M._cur_path .. ".channel")

_M._cur_path = path .. ".core.transport.router"
_M.core.transport.router = require(_M._cur_path .. ".router")

_M._cur_path = path .. ".core.transport"
_M.core.transport.serialize = require(_M._cur_path .. ".serialize")
_M.core.transport.henet = require(_M._cur_path .. ".henet")

-- == connection
_M._cur_path = path .. ".core"
_M.core.connection = require(_M._cur_path .. ".connection")

-- === manager
_M._cur_path = path .. ".core.event"

_M.core.event = {}
_M.core.event.serverSide = require(_M._cur_path .. ".serverSide")
_M.core.event.clientSide = require(_M._cur_path .. ".clientSide")

_M.core.event.attach = {}
_M._cur_path = path .. ".core.event.attach"
_M.core.event.attach = require(_M._cur_path .. ".attach")
_M._cur_path = path .. ".core.event"

_M.core.event.manager = require(_M._cur_path .. ".manager")


-- === storage
_M._cur_path = path .. ".storage"

_M.storage = {}
_M.storage.recorder = require(_M._cur_path .. ".recorder")
_M.storage.storage = require(_M._cur_path .. ".storage")
--_M.storage.snapshot = require(_M._cur_path .. ".snapshot")

-- === replication
_M._cur_path = path .. ".replication"

-- === services
_M._cur_path = path .. ".services"

--_M.services = {}
--_M.services.chat = require(_M._cur_path .. ".chat")
--_M.services.teams = require(_M._cur_path .. ".teams")
--_M.services.votekick = require(_M._cur_path .. ".votekick")
--_M.services.commands = require(_M._cur_path .. ".commands")
--_M.services.scoreboard = require(_M._cur_path .. ".scoreboard")
--_M.services.chat = require(_M._cur_path .. ".storage")

-- === main
_M._cur_path = path .. ".main"

_M.main = {}
_M.main.client = require(_M._cur_path .. ".client")
_M.main.server = require(_M._cur_path .. ".server")

return _M