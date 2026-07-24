# ============================================================================
# common.mk - Shared targets for PF ecosystem FastAPI microservices
# ============================================================================
#
# This Makefile provides common development workflows for FastAPI + PostgreSQL
# microservices in the PF ecosystem.
#
# USAGE:
#   Include this file at the top of your service Makefile:
#
#     include ../pf-common/make/common.mk
#
# REQUIRED VARIABLES (define BEFORE include):
#   APP_PORT          - Port for uvicorn server (e.g., 8000, 8001)
#   APP_MODULE        - Python module path (e.g., payroll.interfaces.api.main:app)
#
# OPTIONAL VARIABLES (override AFTER include if needed):
#   PYTHON            - Python interpreter (default: python3.12)
#   VENV              - Virtual environment path (default: .venv)
#   ENV_FILE          - Environment file (default: .env)
#
# AVAILABLE TARGETS:
#   install           - Create venv, install deps, configure git hooks
#   reinstall         - Clean + install
#   test              - Run pytest suite
#   test-cov          - Run pytest with 100% coverage requirement
#   lint              - Run ruff linter + formatter
#   dead-code         - Detect unused code with vulture
#   typecheck         - Run mypy type checker
#   duplicate-code-*  - Detect code duplication with jscpd
#   security-scan     - Scan for misconfigs and secrets with trivy
#   check             - Run all quality gates in sequence
#   clean             - Remove caches and build artifacts
#   run               - Run FastAPI server with auto-reload
#   unset-proxy-vars  - Clear proxy environment variables
#   install-python    - Install Python 3.12 via pyenv
#
# DOCUMENTATION:
#   See ../pf-common/make/README.md for detailed documentation.
#
# ============================================================================

# Prevent direct execution
ifndef APP_PORT
$(error APP_PORT must be defined before including common.mk)
endif
ifndef APP_MODULE
$(error APP_MODULE must be defined before including common.mk. Example: payroll.interfaces.api.main:app)
endif

# Load .env values (if the file exists) before any ?= defaults
-include .env

# ============================================================================
# Variables
# ============================================================================

# Python configuration
PYTHON ?= python3.12
VENV ?= .venv
ENV_FILE ?= .env
VENV_BIN = PATH="$(VENV)/bin:$$PATH"

# Corporate registry URLs (set in .env; empty here so .env values take priority)
CORPORATIVE_PIP_INDEX ?=
CORPORATIVE_NPM_REGISTRY ?=
CORPORATIVE_PROXY ?=

# Docker/testcontainers: auto-detect Rancher Desktop socket and disable Ryuk
_RANCHER_SOCK = $(HOME)/.docker/run/docker.sock
_DOCKER_ENV = $(if $(wildcard $(_RANCHER_SOCK)),DOCKER_HOST=unix://$(_RANCHER_SOCK) TESTCONTAINERS_RYUK_DISABLED=true,)

# Helper to unset common proxy variables
UNSET_PROXY_VARS = bash -eu -o pipefail -c 'vars=(http_proxy https_proxy all_proxy no_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY NO_PROXY); for v in "$${vars[@]}"; do if [[ -n "$${!v-}" ]]; then printf "  Unsetting %s -> %s\\n" "$$v" "$${!v}"; unset "$$v"; else printf "  • %s not set\\n" "$$v"; fi; done'

# ============================================================================
# Development Lifecycle
# ============================================================================

.PHONY: install
install: ## Create venv, install dependencies, configure git hooks
	@python_bin=$$(for v in python3.14 python3.13 python3.12 python3; do \
		if command -v "$$v" >/dev/null 2>&1 && "$$v" -c "import sys; sys.exit(0 if sys.version_info>=(3,12) else 1)" 2>/dev/null; then \
			echo "$$v"; break; \
		fi; \
	done); \
	[ -n "$$python_bin" ] || { \
		echo ""; \
		echo "ERROR: Python >=3.12 not found in PATH."; \
		echo ""; \
		echo "  Option 1 — pyenv (recommended if already installed):"; \
		echo "    pyenv install 3.12 && pyenv local 3.12"; \
		echo ""; \
		echo "  Option 2 — install pyenv without brew (works on Corporative VPN):"; \
		echo "    curl -fsSL https://pyenv.run | bash"; \
		echo "    # then add to your shell profile and restart terminal"; \
		echo "    pyenv install 3.12 && pyenv local 3.12"; \
		echo ""; \
		echo "  Option 3 — download installer from https://www.python.org/downloads/"; \
		echo ""; \
		echo "  Then re-run: make reinstall"; \
		echo ""; \
		exit 1; \
	}; \
	echo "  -> Using $$python_bin ($$($$python_bin --version))"; \
	"$$python_bin" -m venv "$(VENV)"
	@if curl -sfL --connect-timeout 3 -o /dev/null "$(CORPORATIVE_PIP_INDEX)/" 2>/dev/null; then \
		echo "  -> Corporative VPN — routing pip through sysproxy"; \
		printf '[global]\\nproxy = $(CORPORATIVE_PROXY)\\n' > "$(VENV)/pip.conf"; \
	else \
		echo "  -> No VPN — disabling corporate proxy env vars for pip"; \
		printf '[global]\\ntrust-env = false\\n' > "$(VENV)/pip.conf"; \
	fi
	. "$(VENV)/bin/activate" && python -m pip install -U pip && python -m pip install -e ".[dev]"
	git config core.hooksPath .githooks
	@echo "  Git hooks configured (.githooks/)"

.PHONY: reinstall
reinstall: clean ## Wipe caches and reinstall from scratch
	rm -rf $(VENV)
	@$(MAKE) --no-print-directory install

.PHONY: clean
clean: ## Remove build artifacts and caches
	rm -rf .coverage htmlcov .pytest_cache .mypy_cache .ruff_cache build dist
	rm -f .coverage.* .dmypy.json dmypy.json
	find . -type d -name __pycache__ -prune -exec rm -rf {} +
	find . -type d -name "*.egg-info" -prune -exec rm -rf {} +

.PHONY: unset-proxy-vars
unset-proxy-vars: ## Clear proxy environment variables
	@$(UNSET_PROXY_VARS)

# ============================================================================
# Application Execution
# ============================================================================

.PHONY: run
run: ## Run FastAPI server with auto-reload
	$(VENV_BIN) uvicorn $(APP_MODULE) --reload --port $(APP_PORT)

# ============================================================================
# Testing
# ============================================================================

.PHONY: test
test: ## Run complete test suite
	$(_DOCKER_ENV) $(VENV_BIN) pytest

.PHONY: test-cov
test-cov: ## Run tests with 100% coverage requirement
	$(_DOCKER_ENV) $(VENV_BIN) pytest --cov=src --cov-report=term-missing --cov-fail-under=100

# ============================================================================
# Quality Checks
# ============================================================================

.PHONY: lint
lint: ## Run ruff linter and formatter
	$(VENV_BIN) ruff check --fix --exit-zero src tests
	$(VENV_BIN) ruff format src tests
	$(VENV_BIN) ruff check src tests

.PHONY: dead-code
dead-code: ## Detect unused code with vulture
	$(VENV_BIN) vulture --config pyproject.toml

.PHONY: typecheck
typecheck: ## Run mypy static type checker
	$(VENV_BIN) mypy --install-types --non-interactive src

.PHONY: duplicate-code
duplicate-code: ## Detect duplicated code across entire repository
	$(MAKE) --no-print-directory _duplicate-code DUPLICATE_PATH=. DUPLICATE_THRESHOLD=0

.PHONY: duplicate-code-tests
duplicate-code-tests: ## Detect duplicated code in tests only
	$(MAKE) --no-print-directory _duplicate-code DUPLICATE_PATH=tests DUPLICATE_THRESHOLD=0

.PHONY: duplicate-code-src
duplicate-code-src: ## Detect duplicated code in src only
	$(MAKE) --no-print-directory _duplicate-code DUPLICATE_PATH=src DUPLICATE_THRESHOLD=0

.PHONY: _duplicate-code
_duplicate-code:
	@if curl -sfL --connect-timeout 2 -o /dev/null "$(CORPORATIVE_NPM_REGISTRY)/" 2>/dev/null; then \
		echo "  -> Corporative VPN detected — using Artifactory npm registry"; \
		export npm_config_registry="$(CORPORATIVE_NPM_REGISTRY)"; \
	fi; \
	npx --yes jscpd --mode strict --min-lines 10 --min-tokens 70 --threshold $(DUPLICATE_THRESHOLD) --reporters console --ignore "**/.venv/**,**/build/**,**/dist/**,**/.github/**" $(DUPLICATE_PATH)

.PHONY: security-scan
security-scan: ## Scan filesystem for misconfigs and secrets
	trivy fs --scanners misconfig,secret --severity HIGH,CRITICAL --exit-code 1 --skip-files '.env' --skip-version-check .

.PHONY: check
check: ## Run all quality gates in sequence
	@set -e; \
	for target in lint dead-code typecheck duplicate-code-src duplicate-code-tests duplicate-code test test-cov security-scan; do \
		echo "==> make $$target"; \
		if ! $(MAKE) --no-print-directory $$target; then \
			echo "FAILED: $$target"; \
			exit 1; \
		fi; \
	done; \
	echo "All checks passed."

# ============================================================================
# Utilities
# ============================================================================

.PHONY: install-python
install-python: ## Install Python 3.12 via pyenv (works on Corporative VPN)
	@if command -v pyenv >/dev/null 2>&1; then \
		echo "  -> pyenv found, installing Python 3.12..."; \
		pyenv install -s 3.12; \
		pyenv local 3.12; \
		echo "  Python 3.12 ready. Re-run: make reinstall"; \
	else \
		echo "  -> pyenv not found, installing via https://pyenv.run ..."; \
		curl -fsSL https://pyenv.run | bash; \
		echo ""; \
		echo "  pyenv installed. Add the following to your shell profile (~/.zshrc or ~/.bashrc),"; \
		echo "    restart your terminal, then run: make install-python"; \
		echo ""; \
		echo '    export PYENV_ROOT="$$HOME/.pyenv"'; \
		echo '    export PATH="$$PYENV_ROOT/bin:$$PATH"'; \
		echo '    eval "$$(pyenv init -)"'; \
	fi

# ============================================================================
# Help
# ============================================================================

.PHONY: help
help: ## Show this help message
	@echo "common.mk - Shared targets for PF ecosystem FastAPI services"
	@echo ""
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-20s %s\n", $$1, $$2}'
	@echo ""
	@echo "Service-specific variables:"
	@echo "  APP_PORT:   $(APP_PORT)"
	@echo "  APP_MODULE: $(APP_MODULE)"
	@echo "  VENV:       $(VENV)"
	@echo "  PYTHON:     $(PYTHON)"
