# ============================================================================
# [SERVICE_NAME] - [SERVICE_DESCRIPTION]
# ============================================================================
#
# Template Makefile for new PF microservice.
# Copy this file to your service directory and customize.
#
# Instructions:
#   1. Replace [SERVICE_NAME] with your service name (e.g., pf-invoices)
#   2. Replace [SERVICE_DESCRIPTION] with brief description
#   3. Set APP_PORT to a free port (8000, 8001, 8002, ...)
#   4. Set APP_MODULE to your FastAPI app module path
#   5. Customize env-write target with service-specific variables
#   6. Add custom targets if needed
#
# ============================================================================

# Service configuration (REQUIRED by common.mk)
APP_PORT := 8XXX  # <-- Choose a free port (check ARCHITECTURE.md)
APP_MODULE := [service_name].interfaces.api.main:app  # <-- Adjust module path

# Include shared targets from pf-common/
include ../pf-common/make/common.mk

# ============================================================================
# Service-specific variables (optional)
# ============================================================================

# Example: External API dependencies
# EXTERNAL_API_URL ?= https://api.example.com

# Example: Database dependency (if using pf-db)
# PF_DATABASE_URL ?= postgresql+asyncpg://pf_db:pf_db@localhost:5432/pf_db

# ============================================================================
# Service-specific targets
# ============================================================================

.PHONY: env-write
env-write: ## Write .env file with service-specific defaults
	@printf 'PF_DATABASE_URL=postgresql+asyncpg://pf_db:pf_db@localhost:5432/pf_db\\n' > $(ENV_FILE)
	@printf '[SERVICE_NAME]_API_KEY=change-me-before-use\\n' >> $(ENV_FILE)
	# Add service-specific environment variables here
	@printf '\\n# Tooling — corporate pip/npm registries (used by make install/check on VPN)\\n' >> $(ENV_FILE)
	@printf 'CORPORATIVE_PIP_INDEX=https://pypi.ci.artifacts.corporative.com/artifactory/api/pypi/pythonhosted-pypi-release-remote/simple\\n' >> $(ENV_FILE)
	@printf 'CORPORATIVE_NPM_REGISTRY=https://npm.ci.artifacts.corporative.com/artifactory/api/npm/external-npm\\n' >> $(ENV_FILE)
	@printf 'CORPORATIVE_PROXY=http://sysproxy.corpo-rative.com:8080\\n' >> $(ENV_FILE)
	@echo "  $(ENV_FILE) written"

.PHONY: local-up
local-up: ## Start full local stack (env, deps, API)
	APP_PORT="$(APP_PORT)" \\
		VENV="$(VENV)" ENV_FILE="$(ENV_FILE)" \\
		./scripts/local_stack.sh

# ============================================================================
# Custom targets (add service-specific functionality here)
# ============================================================================

# Example: Import data via CLI
# .PHONY: import-data
# import-data:
#     @test -n "$(DATA_FILE)" || (echo "DATA_FILE is required. Usage: make import-data DATA_FILE=data.csv" && exit 1)
#     PYTHONPATH=src "$(VENV)/bin/python" -m [service_name].cli import "$(DATA_FILE)"

# Example: Override clean to add custom cleanup
# .PHONY: clean
# clean:
#     @$(MAKE) -f ../pf-common/make/common.mk clean  # Call common clean first
#     rm -f my-custom-artifacts.pdf
#     rm -rf my-custom-cache/
