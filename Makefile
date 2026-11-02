.PHONY: help install dry-run lint test test-docker list

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

install: ## Run the full installer (interactive)
	./install.sh

dry-run: ## Show what the installer would do
	./install.sh --dry-run --yes

list: ## List modules
	./install.sh --list

lint: ## shellcheck every script
	./tests/lint.sh

test: lint ## Lint + smoke tests (no changes to your machine)
	./tests/smoke.sh

test-docker: ## Full install inside a clean ubuntu:24.04 container
	./tests/docker/run.sh
