local _M = {}

-- Initialize module
function _M.init()
    -- Get existing random seed function if it exists
    local existing_random = _G.math.randomseed
    
    -- Seed math.random once. Use current time + microseconds to reduce collisions.
    local seed = os.time() + (ngx.now() * 1000000)
    if existing_random then
        existing_random(seed)
    else
        math.randomseed(seed)
    end
end

-- Generate a UUIDv7
function _M.generate_uuid()
    local random = math.random
    local floor = math.floor
    local now = ngx.now
    local bit = bit
    local band = bit.band
    local bor = bit.bor
    local rshift = bit.rshift

    -- 1) Create a 16-byte array with random values in each byte
    local bytes = {}
    for i = 1, 16 do
        bytes[i] = random(0, 255)
    end

    -- 2) Get current Unix timestamp in milliseconds (with sub-second precision)
    local timestamp_ms = floor(now() * 1000)

    -- 3) Store those 48 bits of timestamp in the first 6 bytes
    bytes[1] = band(rshift(timestamp_ms, 40), 0xFF)
    bytes[2] = band(rshift(timestamp_ms, 32), 0xFF)
    bytes[3] = band(rshift(timestamp_ms, 24), 0xFF)
    bytes[4] = band(rshift(timestamp_ms, 16), 0xFF)
    bytes[5] = band(rshift(timestamp_ms,  8), 0xFF)
    bytes[6] = band(timestamp_ms, 0xFF)

    -- 4) Set the UUID version to 7 in byte 7 (top 4 bits => 0111)
    bytes[7] = bor(band(bytes[7], 0x0F), 0x70)

    -- 5) Set the RFC4122 variant bits in byte 9 (top 2 bits => 10)
    bytes[9] = bor(band(bytes[9], 0x3F), 0x80)

    -- 6) Convert to a standard 8-4-4-4-12 UUID string
    local hexparts = {}
    for i = 1, 16 do
        hexparts[i] = string.format("%02x", bytes[i])
    end
    local full = table.concat(hexparts)
    local uuid_str = table.concat({
        string.sub(full, 1, 8),
        string.sub(full, 9, 12),
        string.sub(full, 13, 16),
        string.sub(full, 17, 20),
        string.sub(full, 21),
    }, "-")

    return uuid_str
end

return _M 