OR_EXEC ?= $(shell which openresty)
LUAROCKS_VER ?= $(shell luarocks --version | grep -E -o  "luarocks [0-9]+.")
LUAJIT_DIR ?= $(shell ${OR_EXEC} -V 2>&1 | grep prefix | grep -Eo 'prefix=(.*)/nginx\s+--' | grep -Eo '/.*/')luajit


### test:         Run test suite
.PHONY: test
test: lint
	prove -I. -r -s t/
	busted


### install:      Install the library to runtime
.PHONY: install
install:
	luarocks install rockspec/api7-lua-resty-dns-client-master-0.rockspec


### deps:         Installation dependencies
.PHONY: deps
deps:
ifneq ($(LUAROCKS_VER),luarocks 3.)
	luarocks install rockspec/api7-lua-resty-dns-client-master-0.rockspec --tree=deps --only-deps --local
else
	luarocks install --lua-dir=$(LUAJIT_DIR) rockspec/api7-lua-resty-dns-client-master-0.rockspec --tree=deps --only-deps --local
endif


### lint:         Lint Lua source code
.PHONY: lint
lint:
	luacheck -q src


### help:         Show Makefile rules
.PHONY: help
help:
	@echo Makefile rules:
	@echo
	@grep -E '^### [-A-Za-z0-9_]+:' Makefile | sed 's/###/   /'
