local pgmoon = require("pgmoon")
local cjson = require("cjson")

local _M = {}

function _M.test_db()
    local pg = pgmoon.new({
        host = os.getenv("DB_HOST"),
        port = os.getenv("DB_PORT"),
        database = os.getenv("DB_NAME"),
        user = os.getenv("DB_USER"),
        password = os.getenv("DB_PASSWORD")
    })

    local ok, err = pg:connect()
    if not ok then
        ngx.status = 500
        ngx.say(cjson.encode({
            success = false,
            error = "Failed to connect: " .. (err or "unknown error")
        }))
        return
    end

    -- Test query to get PostgreSQL version
    local res, err = pg:query("SELECT version()")
    if not res then
        ngx.status = 500
        ngx.say(cjson.encode({
            success = false,
            error = "Failed to query: " .. (err or "unknown error")
        }))
        return
    end

    pg:keepalive()

    ngx.say(cjson.encode({
        success = true,
        version = res[1].version
    }))
end

return _M 