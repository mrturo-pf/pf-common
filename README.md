# pf-common - Shared Infrastructure for PF Ecosystem

This repository contains shared infrastructure, scripts, and configurations used across all PF microservices.

## Overview

pf-common provides reusable Make targets, validation scripts, and templates for FastAPI microservices in the PF ecosystem.

**Services using pf-common:**
- [pf-payroll](../pf-payroll) - Chilean payroll microservice
- [pf-rates](../pf-rates) - Financial reference data microservice
- Future services...

**NOT used by:**
- [pf-db](../pf-db) - Database repository (different type)

## Directory Structure

```
pf-common/
├── GIT_SETUP.md                   # Instructions to initialize as git repo
├── README.md                      # This file
├── make/
│   ├── common.mk                  # Shared Make targets for FastAPI services
│   ├── README.md                  # Usage guide for common.mk
│   └── templates/
│       └── service.mk             # Template Makefile for new services
├── scripts/                       # Shared utility scripts
│   └── sync_deps.py               # Validate dependency sync across services
└── (future additions as needed)
```

## What Goes Here?

### `common/make/`

Shared Makefile infrastructure for FastAPI microservices:

- **common.mk** - Shared targets (install, test, lint, check, etc.)
- **templates/** - Makefile templates for new services

**Used by:** pf-payroll, pf-rates, and future FastAPI services  
**NOT used by:** pf-db (different type of repo)

See [make/README.md](make/README.md) for detailed usage.

### `common/scripts/`

Shared utility scripts used across multiple repositories:

- **sync_deps.py** - Validates that core dependencies are synchronized

**Usage:**
```bash
python common/scripts/sync_deps.py
```

### Future Additions

As the ecosystem grows, consider adding:

```
common/
├── docker/                    # Shared Dockerfile templates
│   └── fastapi.Dockerfile
├── configs/                   # Shared configuration files
│   ├── ruff.toml              # Shared ruff config
│   └── pytest.ini             # Shared pytest config
├── workflows/                 # Shared GitHub Actions workflows
│   └── deploy.yml
├── schemas/                   # Shared data schemas
│   └── api_response.json
└── docs/                      # Shared documentation templates
    └── API_TEMPLATE.md
```

## Usage Examples

### Using common.mk in a New Service

1. Create your service Makefile:

```makefile
# pf-new-service/Makefile

APP_PORT := 8002
APP_MODULE := new_service.interfaces.api.main:app

include ../common/make/common.mk

.PHONY: env-write
env-write:
    # Service-specific .env generation
```

2. Run standard commands:

```bash
make install      # Create venv, install deps
make test         # Run tests
make check        # Run all quality gates
make run          # Start service on port 8002
```

### Creating a New Service from Template

```bash
# 1. Copy template
mkdir pf-new-service
cp common/make/templates/service.mk pf-new-service/Makefile

# 2. Customize
cd pf-new-service
# Edit Makefile: set APP_PORT, APP_MODULE, etc.

# 3. Initialize
make install
make env-write
```

### Running Shared Scripts

```bash
# Validate dependeynchronization
python common/scripts/sync_deps.py

# Add to CI (.github/workflows/test.yml)
- name: Check dependency sync
  run: python common/scripts/sync_deps.py
```

## Design Principles

1. **DRY (Don't Repeat Yourself)** - Common logic in one place
2. **Opt-in** - Services include only what they need
3. **Overrideable** - Services can customize any target
4. **Well-documented** - Clear usage guides and examples
5. **Versioned** - Changes tracked via git history

## Maintenance Guidelines

### Adding New Shared Infrastructure

1. **Evaluate necessity:** Will 3+ repos benefit?
2. **Document well:** Update this README + specific README
3. **Test with existing services:** Ensure no breakage
4. **Announce:** Notify team of new shared resource

### Modifying Existing Infrastructure

1. **Check impact:** Which services use this?
2. **Backward compatibility:** Avoid breaking changes if possible
3. **Update documentation:** Keep READMEs current
4. **Test thoroughly:** Run checks on all affected services
5. **Communicate:** Announce breaking changes

### Deprecating Infrastructure

1. **Announce deprecation:** Give advance notice
2. **Provide migration path:** Document how to update
3. **Set deadline:** Allow time for migration
4. **Remove cleanly:** Delete files, update docs

## Contributing

When adding new shared infrastructure:

1. Create a feature branch
2. Add files to appropriate `common/` subdirectory
3. Update this README
4. Test with at least one existing service
5. Submit PR with clear description of benefit

## Questions?

- **Make targets not working?** Check [make/README.md](make/README.md)
- **Script errors?** Check script documentation in `scripts/`
- **New infrastructure needed?** Open an issue to discuss

## See Also

- [ARCHITECTURE.md](../ARCHITECTURE.md) - Ecosystem overview
- [make/README.md](make/README.md) - Makefile usage guide
- Service-specific READMEs in each repository
