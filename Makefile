# RHDH Local — common developer tasks. Run `make help` for the list.
#
#   TOOL              container tool to use, default podman (TOOL=docker to use Docker)
#   OVERLAYS          overlays applied on top of compose.yaml, space-separated.
#                     Accepts the named overlays below or a path to any compose file,
#                     e.g. make start OVERLAYS="db orchestrator"
#   DCLINT_IMAGE      dclint image used by `make lint`, pinned to a release tag
#   SHELLCHECK_IMAGE  shellcheck image used by `make lint`, pinned to a release tag
#   SERVICE           service to act on for `make logs`, default all services
#
TOOL ?= podman
OVERLAYS ?=
SERVICE ?=

# Named overlays, so nobody has to remember compose file names.
OVERLAY_NAMES := db corporate-proxy dynamic-plugins-root orchestrator
OVERLAY_db                   := compose-with-db.yaml
OVERLAY_corporate-proxy      := compose-with-corporate-proxy.yaml
OVERLAY_dynamic-plugins-root := compose-dynamic-plugins-root.yaml
OVERLAY_orchestrator         := orchestrator/compose.yaml

unknown_overlays := $(filter-out $(OVERLAY_NAMES) %.yaml,$(OVERLAYS))
ifneq ($(strip $(unknown_overlays)),)
$(error Unknown OVERLAYS entry: $(unknown_overlays) (use: $(OVERLAY_NAMES), or a *.yaml path))
endif

OVERLAY_FILES := $(foreach overlay,$(OVERLAYS),$(if $(filter %.yaml,$(overlay)),$(overlay),$(OVERLAY_$(overlay))))
# Compose only auto-detects compose.yaml and compose.override.yaml when no -f is
# given, so naming an overlay means naming the base file too.
COMPOSE_ARGS := $(if $(strip $(OVERLAYS)),-f compose.yaml $(addprefix -f ,$(OVERLAY_FILES)))
COMPOSE := $(strip $(TOOL) compose $(COMPOSE_ARGS))

DCLINT_IMAGE ?= docker.io/zavoloklom/dclint:3.1.0
SHELLCHECK_IMAGE ?= docker.io/koalaman/shellcheck:v0.11.0
LINT_MOUNT := -v "$(CURDIR)":/app:ro,z -w /app

.PHONY: help start stop restart logs ps list-services effective-compose plugins-install down clean reset lint

.DEFAULT_GOAL := help

help: ## Show this help
	@grep -hE '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-17s\033[0m %s\n", $$1, $$2}'
	@printf '\n  OVERLAYS: %s (or a path to any compose file)\n' "$(OVERLAY_NAMES)"
	@printf '  e.g. make start OVERLAYS="db orchestrator"\n'
	@printf '  e.g. make logs SERVICE=rhdh\n'

start: ## Start RHDH Local
	$(COMPOSE) up -d

stop: ## Stop RHDH only, leaving the containers in place
	$(COMPOSE) stop rhdh

restart: ## Restart RHDH only, for configuration changes
	$(COMPOSE) stop rhdh
	$(COMPOSE) start rhdh

logs: ## Follow logs for all services, or SERVICE=rhdh for one
	$(COMPOSE) logs -f $(SERVICE)

ps: ## Show all containers, including stopped ones
	$(COMPOSE) ps -a

list-services: ## List the services defined by the compose files
	$(COMPOSE) config --services

effective-compose: ## Render the effective Compose config
	$(COMPOSE) config

plugins-install: ## Reinstall dynamic plugins, then restart RHDH
	$(COMPOSE) run install-dynamic-plugins
	$(COMPOSE) stop rhdh
	$(COMPOSE) start rhdh

down: ## Stop and remove all containers and the network, keeping volumes
	$(COMPOSE) down

clean: ## Stop everything and remove volumes
	$(COMPOSE) down --volumes

reset: ## Remove containers, volumes, and every pulled image
	$(COMPOSE) down --volumes --rmi all
	-$(TOOL) rmi $(DCLINT_IMAGE) $(SHELLCHECK_IMAGE) 2>/dev/null

lint: ## Lint the tracked compose files and shell scripts
	$(TOOL) run --rm $(LINT_MOUNT) $(DCLINT_IMAGE) \
		$(shell git ls-files 'compose*.yaml' 'orchestrator/compose*.yaml')
	$(TOOL) run --rm $(LINT_MOUNT) $(SHELLCHECK_IMAGE) \
		$(shell git ls-files '*.sh')
