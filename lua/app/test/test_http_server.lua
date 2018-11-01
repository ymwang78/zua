local zce = require "zce.core"
local lu = require('util.luaunit')

function on_http_event(con, event, data)
    if event == "CONN" then
    elseif event == "READ" then
        zce.log(1, "\t", data.method, data.uri, data.body)
        zce.http_response(con, 200, { ["Content-Type"] =  "Application/Json;charset=UTF-8"}, data.body)
        zce.tcp_close(con);
    elseif event == "DISC" then
    end
end

local ok, listenobj = zce.tcp_listen("http", "0.0.0.0", 8080, on_http_event)
lu.assertEquals(ok, true)

c.usleep(5000)

local ok = zce.tcp_close(listenobj)
lu.assertEquals(ok, true)
