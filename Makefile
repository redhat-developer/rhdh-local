.PHONY: start stop restart clean plugins-install lint

## Start RHDH Local (default Podman; set TOOL=docker to use Docker)
TOOL ?= podman

start:
	$(TOOL) compose up -d

stop:
	$(TOOL) compose down

restart: stop start

clean:
	$(TOOL) compose down --volumes

plugins-install:
	$(TOOL) compose run install-dynamic-plugins
	$(TOOL) compose stop rhdh
	$(TOOL) compose start rhdh

lint:
	npx dclint .
	shellcheck *.sh
