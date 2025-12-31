use Test::Nginx::Socket;

plan('no_plan');

our $HttpConfig = qq{
    lua_package_path "deps/share/lua/5.1/?.lua;deps/share/lua/5.1/?.lua;src/?.lua;src/?/?.lua;src/?/init.lua;;";
};

run_tests();

__DATA__

=== TEST 1: DNS chain 10ttl -> 3ttl -> 10ttl, use 3ttl as the expiration time
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        access_by_lua_block {
            local resolver = require("resty.dns.resolver")
            local old_query = resolver.query
            resolver.query = function(self, qname, opts, tries)
                ngx.log(ngx.INFO, "resolver query for ", qname)
                return old_query(self, qname, opts, tries)
            end

            local client = require("resty.dns.client")
            assert(client.init({
                nameservers = { {"127.0.0.1", 15353} },
                order = {"LAST","A","AAAA", "CNAME" },
                finalCacheOnly = true,
            }))

            for i = 1, 10 do
                local answers, err = client.resolve("run.api7.ai", { qtype = client.TYPE_A })
                assert(err == nil, err)
                assert(#answers > 0, "no answers returned")
                assert(answers[1].address == "18.155.68.66", "unexpected address: " .. (answers[1].address or "nil"))
                ngx.sleep(1)  -- Adding a sleep to avoid overwhelming the resolver
            end
            ngx.say("passed")
        }
    }
--- request
GET /t
--- response_body
passed
--- grep_error_log eval
qr/resolver query for run.api7.ai/
--- grep_error_log_out
resolver query for run.api7.ai
resolver query for run.api7.ai
resolver query for run.api7.ai
--- timeout: 15
