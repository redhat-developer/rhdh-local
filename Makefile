# RHDH Local — common developer tasks. Run `make help` for the list.
#
#   TOOL              container tool to use, default podman (TOOL=docker to use Docker)
#   OVERLAYS          overlays applied on top of compose.yaml, space-separated.
#                     Accepts the named overlays below or a path to any compose file,
#                     e.g. make start OVERLAYS="db orchestrator"
#   DCLINT_IMAGE      dclint image used by `make lint`, pinned to a release tag
#   SHELLCHECK_IMAGE  shellcheck image used by `make lint`, pinned to a release tag
#
TOOL ?= podman
OVERLAYS ?=

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

.PHONY: help start stop restart plugins-install down clean lint

.DEFAULT_GOAL := help

help: ## Show this help
	@grep -hE '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-17s\033[0m %s\n", $$1, $$2}'
	@printf '\n  OVERLAYS: %s (or a path to any compose file)\n' "$(OVERLAY_NAMES)"
	@printf '  e.g. make start OVERLAYS="db orchestrator"\n'

start: ## Start RHDH Local
	$(COMPOSE) up -d

stop: ## Stop RHDH only, leaving the containers in place
	$(COMPOSE) stop rhdh

restart: ## Restart RHDH only, for configuration changes
	$(COMPOSE) stop rhdh
	$(COMPOSE) start rhdh

plugins-install: ## Reinstall dynamic plugins, then restart RHDH
	$(COMPOSE) run install-dynamic-plugins
	$(COMPOSE) stop rhdh
	$(COMPOSE) start rhdh

down: ## Stop and remove all containers and the network, keeping volumes
	$(COMPOSE) down

clean: ## Stop everything and remove volumes
	$(COMPOSE) down --volumes

lint: ## Lint the tracked compose files and shell scripts
	$(TOOL) run --rm $(LINT_MOUNT) $(DCLINT_IMAGE) \
		$(shell git ls-files 'compose*.yaml' 'orchestrator/compose*.yaml')
	$(TOOL) run --rm $(LINT_MOUNT) $(SHELLCHECK_IMAGE) \
		$(shell git ls-files '*.sh')
