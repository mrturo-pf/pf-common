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
#   5. Create scripts/write_env.sh (copy the pattern from pf-payroll or
#      pf-rates: source ../../pf-common/scripts/write_env_common.sh, print
#      the service-specific lines, then call pf_corporate_tooling_env_block)
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

# scripts/write_env.sh should source ../pf-common/scripts/write_env_common.sh
# and call pf_corporate_tooling_env_block at the end -- see pf-payroll/pf-rates
# for the reference implementation. Its CORPORATIVE_* defaults already point
# at the real Walmart Artifactory/proxy endpoints, so you only need to pass
# through service-specific vars (PF_DATABASE_URL, [SERVICE_NAME]_API_KEY, ...).
.PHONY: env-write
env-write: ## Write .env file with service-specific defaults (delegates to scripts/write_env.sh)
	@PF_DATABASE_URL="$(PF_DATABASE_URL)" \
		CORPORATIVE_PIP_INDEX="$(CORPORATIVE_PIP_INDEX)" \
		CORPORATIVE_NPM_REGISTRY="$(CORPORATIVE_NPM_REGISTRY)" \
		CORPORATIVE_PROXY="$(CORPORATIVE_PROXY)" \
		ENV_FILE="$(ENV_FILE)" \
		./scripts/write_env.sh >/dev/null
	@echo "  $(ENV_FILE) written"

.PHONY: local-up
local-up: ## Start full local stack (env, deps, API)
	APP_PORT="$(APP_PORT)" \
		VENV="$(VENV)" ENV_FILE="$(ENV_FILE)" \
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
