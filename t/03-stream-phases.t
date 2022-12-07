use Test::Nginx::Socket::Lua::Stream;

repeat_each(2);
plan('no_plan');

run_tests();

__DATA__

=== TEST 1: support preread phase in stream subsystem
--- stream_config eval
    "lua_package_path 'src/?.lua;;';"
--- stream_server_config
    preread_by_lua_block {
        local client = require("resty.dns.client")
        assert(client.init())
        local host = "localhost"
        local typ = client.TYPE_A
        local answers, err = client.resolve(host, { qtype = typ })

        if not answers then
            ngx.say("failed to resolve: ", err)
        end

        ngx.print("address name: ", answers[1].name)
    }

    content_by_lua_block {
        return;
    }
--- stream_response chop
address name: localhost
