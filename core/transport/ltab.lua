-- ltab.lua
-- ltab (lua table and binary). tab (table and binary)
-- by: MB 2025
-- remaking of tab.dll

local ffi = require("ffi")
local bit = require("bit")

local _M = {}

_M._VERSION = "1.1"

local MAGIC = "\1\0LTAB\0ltab\0"
local VERSION_SIZE = 16
local MAX_PAYLOAD = 65536
local MAX_DEPTH = 64
local EXTRA = 8 -- length + crc (1.1 only)

local HEADER_MIN = #MAGIC + VERSION_SIZE
local MAX_PACKET = HEADER_MIN + EXTRA + MAX_PAYLOAD

local versions = {
    ["1.0"] = false,
    ["1.1"] = true
}

local T = {
    int = 0,
    float = 1,
    char = 2,
    string = 3,
    estring = 4,
    ["false"] = 5,
    ["true"] = 6,
    etable = 7,
    table = 8
}

local INT_MIN = -2 ^ 63
local INT_MAX = 2 ^ 63

local i64 = ffi.new("int64_t[1]")
local f64 = ffi.new("double[1]")

local function fail(code, msg, pos)
    if pos then
        msg = msg .. " (offset " .. pos .. ")"
    end
    return nil, msg, code
end

local function setErr(st, code, msg, pos)
    if not st.err then
        st.err = {code, msg, pos}
    end
    return false
end

local function u8(v)
    return string.char(v)
end

local function packI64(v)
    i64[0] = v
    return ffi.string(i64, 8)
end

local function packF64(v)
    f64[0] = v
    return ffi.string(f64, 8)
end

local function packU32(v)
    return string.char(v % 256, math.floor(v / 256) % 256, math.floor(v / 65536) % 256, math.floor(v / 16777216) % 256)
end

local function unpackU32(data, pos)
    local a, b, c, d = data:byte(pos, pos + 3)
    return a + b * 256 + c * 65536 + d * 16777216
end

local crcTable = {}
for i = 0, 255 do
    local c = i
    for _ = 1, 8 do
        if bit.band(c, 1) == 1 then
            c = bit.bxor(bit.rshift(c, 1), 0xEDB88320)
        else
            c = bit.rshift(c, 1)
        end
    end
    crcTable[i] = c
end

local function crc32(s)
    local c = bit.bnot(0)
    for i = 1, #s do
        c = bit.bxor(crcTable[bit.band(bit.bxor(c, s:byte(i)), 0xFF)], bit.rshift(c, 8))
    end
    return bit.bnot(c) % 4294967296
end

local function formatVersion(v)
    return (v .. string.rep("\0", VERSION_SIZE)):sub(1, VERSION_SIZE)
end

-- pack

local function emit(st, s)
    st.size = st.size + #s
    if st.size > MAX_PAYLOAD then
        return setErr(st, "too_large", "payload too large. x > 64kb")
    end
    st.out[#st.out + 1] = s
    return true
end

local function packValue(value, st, depth)
    local t = type(value)

    if t == "number" then
        if value == math.floor(value) and value >= INT_MIN and value < INT_MAX then
            return emit(st, u8(T.int) .. packI64(value))
        end
        return emit(st, u8(T.float) .. packF64(value))
    elseif t == "string" then
        local len = #value
        if len == 0 then
            return emit(st, u8(T.estring))
        elseif len == 1 then
            return emit(st, u8(T.char) .. value)
        end
        return emit(st, u8(T.string) .. packI64(len) .. value)
    elseif t == "boolean" then
        return emit(st, u8(value and T["true"] or T["false"]))
    elseif t == "table" then
        depth = depth + 1
        if depth > MAX_DEPTH then
            return setErr(st, "too_deep", "table nesting deeper than " .. MAX_DEPTH)
        end
        if st.seen[value] then
            return setErr(st, "cyclic", "cyclic table reference")
        end

        local count = 0
        for k in pairs(value) do
            local kt = type(k)
            if kt ~= "number" and kt ~= "string" and kt ~= "boolean" then
                return setErr(st, "unsupported_type", "unsupported key type: " .. kt)
            end
            count = count + 1
        end

        if count == 0 then
            return emit(st, u8(T.etable))
        end

        st.seen[value] = true
        if not emit(st, u8(T.table) .. packI64(count)) then
            return false
        end
        for k, v in pairs(value) do
            if not (packValue(k, st, depth) and packValue(v, st, depth)) then
                return false
            end
        end
        st.seen[value] = nil

        return true
    end

    return setErr(st, "unsupported_type", "unsupported type: " .. t)
end

function _M.pack(value, opts)
    if opts ~= nil and type(opts) ~= "table" then
        return fail("bad_argument", "opts must be a table, got " .. type(opts))
    end

    local version = opts and rawget(opts, "version") or _M._VERSION

    if type(version) ~= "string" or versions[version] == nil then
        return fail("incompatible_version", "cannot write version '" .. tostring(version) .. "'")
    end

    local st = {
        out = {},
        size = 0,
        seen = {}
    }

    if not packValue(value, st, 0) then
        return fail(st.err[1], st.err[2], st.err[3])
    end

    local payload = table.concat(st.out)
    local head = MAGIC .. formatVersion(version)

    if versions[version] then
        return head .. packU32(#payload) .. packU32(crc32(payload)) .. payload
    end

    return head .. payload
end

-- unpack
local function need(st, n, what)
    if st.pos + n - 1 > st.last then
        return setErr(st, "truncated", what .. ": need " .. n .. " byte(s), " .. (st.last - st.pos + 1) .. " left", st.pos)
    end
    return true
end

local function readU8(st, what)
    if not need(st, 1, what) then
        return nil
    end
    local b = st.data:byte(st.pos)
    st.pos = st.pos + 1
    return b
end

local function readI64(st, what)
    if not need(st, 8, what) then
        return nil
    end
    ffi.copy(i64, st.data:sub(st.pos, st.pos + 7), 8)
    st.pos = st.pos + 8
    return tonumber(i64[0])
end

local function readF64(st, what)
    if not need(st, 8, what) then
        return nil
    end
    ffi.copy(f64, st.data:sub(st.pos, st.pos + 7), 8)
    st.pos = st.pos + 8
    return f64[0]
end

local function readValue(st, isKey)
    local tagPos = st.pos
    local t = readU8(st, "type tag")

    if t == nil then
        return nil
    end

    if isKey and (t == T.table or t == T.etable) then
        setErr(st, "invalid_key", "table used as key", tagPos)
        return nil
    end

    if t == T.int then
        return readI64(st, "int")
    elseif t == T.float then
        return readF64(st, "float")
    elseif t == T.char then
        local c = readU8(st, "char")
        return c and string.char(c)
    elseif t == T.string then
        local lenPos = st.pos
        local len = readI64(st, "string length")
        if len == nil then
            return nil
        end

        local left = st.last - st.pos + 1
        if len < 0 or len > left then
            setErr(st, "invalid_length", "string length " .. len .. " > remaining " .. left, lenPos)
            return nil
        end

        local str = st.data:sub(st.pos, st.pos + len - 1)
        st.pos = st.pos + len
        return str
    elseif t == T.estring then
        return ""
    elseif t == T["false"] then
        return false
    elseif t == T["true"] then
        return true
    elseif t == T.etable then
        return {}
    elseif t == T.table then
        local countPos = st.pos
        local count = readI64(st, "table count")
        if count == nil then
            return nil
        end

        -- every entry is at least 2 bytes (key tag + value tag)
        local left = st.last - st.pos + 1
        if count < 1 or count * 2 > left then
            setErr(st, "invalid_count", "table count " .. count .. " impossible with " .. left .. " byte(s) left", countPos)
            return nil
        end

        st.depth = st.depth + 1
        if st.depth > MAX_DEPTH then
            setErr(st, "too_deep", "table nesting deeper than " .. MAX_DEPTH, tagPos)
            return nil
        end

        local tbl = {}
        for i = 1, count do
            local keyPos = st.pos
            local k = readValue(st, true)
            if k == nil then
                return nil
            end
            if k ~= k then
                setErr(st, "invalid_key", "NaN key", keyPos)
                return nil
            end

            local v = readValue(st, false)
            if v == nil then
                return nil
            end

            if tbl[k] ~= nil then
                setErr(st, "duplicate_key", "duplicate key in entry " .. i .. "/" .. count, keyPos)
                return nil
            end
            tbl[k] = v
        end
        st.depth = st.depth - 1

        return tbl
    end

    setErr(st, "invalid_type", "unknown type tag " .. t, tagPos)
    return nil
end

function _M.unpack(data)
    if type(data) ~= "string" then
        return fail("bad_argument", "packet must be a string, got " .. type(data))
    end

    local size = #data
    if size > MAX_PACKET then
        return fail("too_large", "packet too large (" .. size .. " bytes)")
    end

    local head = data:sub(1, #MAGIC)
    if head ~= MAGIC then
        if size < #MAGIC and MAGIC:sub(1, size) == head then
            return fail("truncated", "packet too small")
        end
        return fail("bad_magic", "invalid magic")
    end

    if size < HEADER_MIN then
        return fail("truncated", "header incomplete (" .. size .. "/" .. HEADER_MIN .. ")")
    end

    local rawVersion = data:sub(#MAGIC + 1, HEADER_MIN)
    if not rawVersion:match("^[^%z]*%z*$") then
        return fail("incompatible_version", "malformed version field", #MAGIC + 1)
    end

    local version = rawVersion:match("^([^%z]*)")
    local checked = versions[version]
    if checked == nil then
        return fail("incompatible_version", "incompatible version '" .. version .. "'", #MAGIC + 1)
    end

    local pos = HEADER_MIN + 1

    if checked then
        if size < HEADER_MIN + EXTRA then
            return fail("truncated", "header incomplete (length/checksum missing)", pos)
        end

        local expectedLen = unpackU32(data, pos)
        local expectedCrc = unpackU32(data, pos + 4)
        pos = pos + EXTRA

        if expectedLen > MAX_PAYLOAD then
            return fail("too_large", "declared payload too large (" .. expectedLen .. ")")
        end

        local actualLen = size - pos + 1
        if actualLen < expectedLen then
            return fail("truncated", "payload truncated: " .. actualLen .. "/" .. expectedLen .. " bytes")
        end
        if actualLen > expectedLen then
            return fail("bad_length", "payload has " .. (actualLen - expectedLen) .. " extra byte(s)")
        end
        if crc32(data:sub(pos)) ~= expectedCrc then
            return fail("bad_checksum", "checksum mismatch, payload corrupted")
        end
    end

    local payloadSize = size - pos + 1
    if payloadSize > MAX_PAYLOAD then
        return fail("too_large", "payload too large")
    end
    if payloadSize < 1 then
        return fail("truncated", "empty payload", pos)
    end

    local st = {
        data = data,
        pos = pos,
        last = size,
        depth = 0
    }

    local value = readValue(st, false)
    if value == nil then
        return fail(st.err[1], st.err[2], st.err[3])
    end

    if st.pos ~= size + 1 then
        return fail("trailing_data", (size - st.pos + 1) .. " unexpected byte(s) after root value", st.pos)
    end

    return value, {
        version = version,
        payloadSize = payloadSize,
        checked = checked
    }
end

function _M.verify(data)
    local value, info, code = _M.unpack(data)
    if value == nil then
        return nil, info, code
    end
    return true, info
end

return _M