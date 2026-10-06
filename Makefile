GREEN := \033[0;32m
YELLOW := \033[1;33m
NC := \033[0m

.DEFAULT_GOAL := help

.PHONY: help
help: ## Show this help message
	@grep -hE '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-24s$(NC) %s\n", $$1, $$2}'

.PHONY: up
up: ## Start the FrankenPHP Moodle stack with Docker Compose
	@./tests/docker/compose-up.sh

.PHONY: down
down: ## Stop the compose stack and remove its volumes
	@docker compose down -v

.PHONY: logs
logs: ## Show recent compose logs
	@docker compose logs --tail=100 -f

.PHONY: trust-local-ca
trust-local-ca: ## Trust Caddy's local root CA on the host machine
	@./docker/trust-local-ca.sh

.PHONY: baseline
baseline: ## Build, install, and verify the FrankenPHP Moodle baseline
	@echo "$(YELLOW)Running FrankenPHP Moodle baseline...$(NC)"
	@./tests/docker/run-baseline.sh

.PHONY: test-preflight
test-preflight: ## Run TLS certificate preflight BATS tests
	@bats tests/bats/test_tls_preflight.bats

.PHONY: test-smoke-bats
test-smoke-bats: ## Run smoke BATS tests
	@bats tests/bats/test_moodle_release_pin.bats tests/bats/test_verify_moodle.bats tests/bats/test_theme_lovely.bats tests/bats/test_config_permissions.bats tests/bats/test_docker_ports.bats tests/bats/test_tls_preflight.bats

.PHONY: test-integration-bats
test-integration-bats: ## Run the end-to-end FrankenPHP baseline BATS test
	@bats tests/bats/test_baseline.bats

.PHONY: test
test: test-smoke-bats ## Run the default test suite
