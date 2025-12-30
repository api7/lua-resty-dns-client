use strict;
use warnings FATAL => 'all';
use Test::Nginx::Socket::Lua;

plan tests => 2;

our $HttpConfig = qq{
    lua_package_path "deps/share/lua/5.1/?.lua;deps/share/lua/5.1/?.lua;src/?.lua;src/?/?.lua;src/?/init.lua;;";
};

run_tests();

__DATA__

=== TEST 1: load lua-resty-dns-client
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        access_by_lua_block {
            local client = require("resty.dns.client")
            assert(client.init({
                resolvConf = {
                    "nameserver 127.0.0.1:15353"
                },
                hosts = {},
                order = {"LAST","A","AAAA", "CNAME" },
            }))
            local host = "run.api7.ai"
            for i = 1, 3 do
                local answers, err = client.resolve(host)
                if err then
                    ngx.log(ngx.ERR, "Failed to resolve ", host, ": ", err)
                    return
                end

                ngx.log(ngx.WARN, "Resolved ", host, ":")

                local inspect = require("inspect")

                for _, ans in ipairs(answers) do
                    ngx.log(ngx.WARN, "Answer: ", inspect(ans))
                end
                ngx.sleep(5)
            end
        }
    }
--- request
GET /t
--- no_error_log
--- timeout: 20
