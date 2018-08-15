local c = require "zce.core"
local lu = require('luaunit')

TestRpc = {}

-- make sure there is a service with name "test_lpcsvr"

local ok, lpcid = c.rpc_ident("lpc", "test_lpcsvr")
lu.assertEquals( ok, true )

local ok, rpcid = c.rpc_ident("rpc", "127.0.0.1", 1218)
lu.assertEquals( ok, true )

function TestRpc:test_call()
	local ok, v0, v1, v2 = c.rpc_call(lpcid, "say_hello", "abcd", 12345)
	c.log(1, " ", "response(say_hello):", ok, v0, v1, v2)
	lu.assertEquals( ok, true )

	local ok, v0, v1, v2 = c.rpc_call(rpcid, "say_hello", "abcd", 12345)
	c.log(1, " ", "response(say_hello):", ok, v0, v1, v2)
	lu.assertEquals( ok, true )
end


function TestRpc:test_call_notsecurity()
	local ok, v0, v1, v2 = c.rpc_call(lpcid, "norpc_say_hello", "abcd", 12345)
	c.log(1, " ", "response(norpc_say_hello):", ok, v0, v1, v2)
	lu.assertEquals( ok, true )

	local ok, v0, v1, v2 = c.rpc_call(rpcid, "norpc_say_hello", "abcd", 12345)
	c.log(1, " ", "response(norpc_say_hello):", ok, v0, v1, v2)
	lu.assertEquals( ok, false )
end

function TestRpc:test_call_timeout()
	local ok, v0, v1, v2 = c.rpc_call(lpcid, "say_hello_timeout", "abcd", 12345)
	c.log(1, " ", "response(say_hello_timeout):", ok, v0, v1, v2)
	lu.assertEquals( ok, false )

	local ok, v0, v1, v2 = c.rpc_call(rpcid, "say_hello_timeout", "abcd", 12345)
	c.log(1, " ", "response(say_hello_timeout):", ok, v0, v1, v2)
	lu.assertEquals( ok, false )
end

function TestRpc:test_call_noresponse()
	local ok, v0, v1, v2 = c.rpc_call(lpcid, "say_hello_noresponse", "abcd", 12345)
	c.log(1, " ", "response(say_hello_noresponse):", ok, v0, v1, v2)
	lu.assertEquals( ok, false )

	local ok, v0, v1, v2 = c.rpc_call(rpcid, "say_hello_noresponse", "abcd", 12345)
	c.log(1, " ", "response(say_hello_noresponse):", ok, v0, v1, v2)
	lu.assertEquals( ok, false )
end

function TestRpc:test_call_delay()
	local ok, v0, v1, v2 = c.rpc_call(lpcid, "say_hello_delay", "abcd", 12345)
	c.log(1, " ", "response(say_hello_delay):", ok, v0, v1, v2)
	lu.assertEquals( ok, true )

	local ok, v0, v1, v2 = c.rpc_call(rpcid, "say_hello_delay", "abcd", 12345)
	c.log(1, " ", "response(say_hello_delay):", ok, v0, v1, v2)
	lu.assertEquals( ok, false )
end

function TestRpc:test_call_cascade()
	local ok, v0, v1, v2 = c.rpc_call(lpcid, "say_hello_cascade", "abcd", 12345)
	c.log(1, " ", "response(say_hello_cascade):", ok, v0, v1, v2)
	lu.assertEquals( ok, true )

	local ok, v0, v1, v2 = c.rpc_call(rpcid, "say_hello_cascade", "abcd", 12345)
	c.log(1, " ", "response(say_hello_cascade):", ok, v0, v1, v2)
	lu.assertEquals( ok, true )
end

lu.run()

c.usleep(100000)

local ok = c.rpc_close(lpcid)
lu.assertEquals( ok, true )

local ok = c.rpc_close(rpcid)
lu.assertEquals( ok, true )