use Test::Nginx::Socket;

plan tests => repeat_each() * (blocks() * 5);

workers(6);

no_shuffle();
run_tests();

__DATA__

=== TEST 1: reuse timers for queries of same name, independent on # of workers
--- http_config eval
qq {
    init_worker_by_lua_block {
        local client = require("resty.dns.client")
        assert(client.init({
            nameservers = { {"127.0.0.1", 15353} },
            hosts = {}, -- empty tables to parse to prevent defaulting to /etc/hosts
            resolvConf = {}, -- and resolv.conf files
            order = { "A" },
        }))
        local host = "svc1.test"
        local typ = client.TYPE_A
        for i = 1, 10 do
            client.resolve(host, { qtype = typ })
        end

        local host = "svc2.test"
        for i = 1, 10 do
            client.resolve(host, { qtype = typ })
        end

        workers = ngx.worker.count()
        timers = ngx.timer.pending_count()
    }
    lua_package_path "deps/share/lua/5.1/?.lua;deps/share/lua/5.1/?.lua;src/?.lua;src/?/?.lua;src/?/init.lua;;";
}
--- config
    location = /t {
        access_by_lua_block {
            local client = require("resty.dns.client")
            assert(client.init({
                nameservers = { {"127.0.0.1", 15353} },
                hosts = {},
                resolvConf = {},
                order = { "A" },
            }))
            local host = "svc1.test"
            local typ = client.TYPE_A
            local answers, err = client.resolve(host, { qtype = typ })

            if not answers then
                ngx.say("failed to resolve: ", err)
                return
            end

            ngx.say("first address name: ", answers[1].name)

            host = "svc2.test"
            answers, err = client.resolve(host, { qtype = typ })

            if not answers then
                ngx.say("failed to resolve: ", err)
                return
            end

            ngx.say("second address name: ", answers[1].name)

            ngx.say("workers: ", workers)

            -- should be 2 timers maximum (1 for each hostname)
            ngx.say("timers: ", timers)
        }
    }
--- request
GET /t
--- response_body
first address name: svc1.test
second address name: svc2.test
workers: 6
timers: 2
--- no_error_log
[error]
dns lookup pool exceeded retries
API disabled in the context of init_worker_by_lua
