# common.mk - Usage Guide

Shared Makefile for PF ecosystem FastAPI microservices.

## Quick Start

1. Create your service Makefile:

```makefile
# Service configuration (REQUIRED before include)
APP_PORT := 8002
APP_MODULE := my_service.interfaces.api.main:app

# Include shared targets
include ../pf-common/make/common.mk

# Service-specific targets
.PHONY: env-write
env-write:
    @printf 'PF_DATABASE_URL=postgresql+asyncpg://pf_db:pf_db@localhost:5432/pf_db\n' > $(ENV_FILE)
    # ... more variables

.PHONY: local-up
local-up:
    ./scripts/local_stack.sh
```

2. Run `make help` to see available targets

3. Run `make install` to set up development environment

## Required Variables

Define these BEFORE `include ../pf-common/make/common.mk`:

| Variable | Description | Example |
|---|---|---|
| `APP_PORT` | Port for uvicorn server | `8000`, `8001`, `8002` |
| `APP_MODULE` | Python module path to FastAPI app | `payroll.interfaces.api.main:app` |

## Optional Variables

Override these AFTER include if needed:

| Variable | Default | Description |
|---|---|---|
| `PYTHON` | `python3.12` | Python interpreter |
| `VENV` | `.venv` | Virtual environment path |
| `ENV_FILE` | `.env` | Environment file |

## Available Targets

### Development Lifecycle

- `make install` - Create venv, install deps, configure git hooks
- `make reinstall` - Clean + install from scratch
- `make clean` - Remove build artifacts and caches
- `make run` - Run FastAPI server with auto-reload on APP_PORT

### Testing

- `make test` - Run pytest suite
- `make test-cov` - Run pytest with 100% coverage requirement

### Quality Checks

- `make lint` - Run ruff linter + formatter
- `make dead-code` - Detect unused code with vulture
- `make typecheck` - Run mypy type checker
- `make duplicate-code` - Detect code duplication (entire repo)
- `make duplicate-code-src` - Detect duplication in src/ only
- `make duplicate-code-tests` - Detect duplication in tests/ only
- `make security-scan` - Scan for misconfigs and secrets with trivy
- `make check` - Run ALL quality gates in sequence

### Utilities

- `make unset-proxy-vars` - Clear proxy environment variables
- `make install-python` - Install Python 3.12 via pyenv
- `make help` - Show available targets

## Customization

### Override a Target

Redefine the target AFTER the include:

```makefile
include ../pf-common/make/common.mk

# Override clean to add service-specific cleanup
clean:
    @$(MAKE) -f ../pf-common/make/common.mk clean  # Call original
    rm -f my-custom-files.pdf
```

### Add Service-Specific Targets

Simply define new targets below the include:

```makefile
include ../pf-common/make/common.mk

.PHONY: import-data
import-data:
    PYTHONPATH=src "$(VENV)/bin/python" -m my_service.cli import "$(DATA_FILE)"
```

## Corporate VPN Support

common.mk automatically detects corporate VPN and configures:

- **pip proxy:** Routes pip through corporate proxy if reachable
- **npm registry:** Routes npx through Artifactory for jscpd

Set these in your `.env`:

```bash
CORPORATIVE_PIP_INDEX=https://pypi.ci.artifacts.corporative.com/artifactory/api/pypi/pythonhosted-pypi-release-remote/simple
CORPORATIVE_NPM_REGISTRY=https://npm.ci.artifacts.corporative.com/artifactory/api/npm/external-npm
CORPORATIVE_PROXY=http://sysproxy.corpo-rative.com:8080
```

## Rancher Desktop Support

common.mk auto-detects Rancher Desktop and configures testcontainers:

- Sets `DOCKER_HOST=unix://~/.docker/run/docker.sock`
- Disables Ryuk (which fails on Rancher Desktop)

No manual configuration needed.

## Examples

See:
- `../../pf-payroll/Makefile` - Full example with CLI, PDF generation
- `../../pf-rates/Makefile` - Minimal example
- `templates/service.mk` - Template for new services
