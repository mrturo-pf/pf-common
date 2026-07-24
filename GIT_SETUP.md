# pf-common - Shared Infrastructure Repository

Shared Make targets, validation scripts, and templates for PF ecosystem FastAPI microservices.

---

## Conversion to Git Repository

This directory has been prepared to become an independent git repository. Follow these steps to initialize it:

```bash
# 1. Navigate to pf-common
cd pf-common

# 2. Initialize git repository
git init

# 3. Create .gitignore
cat > .gitignore << 'EOF'
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
*.egg-info/

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db
EOF

# 4. Add all files
git add .

# 5. Initial commit
git commit -m "feat: initial commit of pf-common shared infrastructure

Contains:
- make/common.mk: Shared Make targets for FastAPI services
- make/templates/service.mk: Template for new services
- scripts/sync_deps.py: Dependency validation script
- Complete documentation

Targets provided:
- install, test, test-cov, check
- lint, dead-code, typecheck, duplicate-code
- security-scan, run, clean

Usage:
  include ../pf-common/make/common.mk

Designed for: pf-payroll, pf-rates, and future FastAPI microservices"

# 6. (Optional) Add remote
git remote add origin <your-git-url>
git push -u origin main
```

---

## Directory Structure

```
pf-common/
├── README.md                              # This file
├── GIT_SETUP.md                           # Git initialization guide
├── make/
│   ├── common.mk                          # Shared Make targets (300 lines)
│   ├── README.md                          # Usage documentation
│   └── templates/
│       └── service.mk                     # Template for new services (40 lines)
└── scripts/
    └── sync_deps.py                       # Dependency validation script
```

---

## Usage in Services

### In pf-payroll/Makefile:

```makefile
# Service configuration
APP_PORT := 8000
APP_MODULE := payroll.interfaces.api.main:app

# Include shared targets from pf-common/
include ../pf-common/make/common.mk

# Service-specific targets
.PHONY: env-write
.PHONY: local-up
```

### In pf-rates/Makefile:

```makefile
# Service configuration
APP_PORT := 8001
APP_MODULE := financial_data.interfaces.api.app:app

# Include shared targets from pf-common/
include ../pf-common/make/common.mk

# Service-specific targets
.PHONY: env-write
.PHONY: local-up
```

---

## Benefits

1. **Single source of truth** - Quality pipeline defined once
2. **Guaranteed consistency** - All services use identical targets
3. **Easy onboarding** - New services: 40 lines vs 250+
4. **Independent versioning** - pf-common can evolve independently
5. **Portable** - Can be used by any PF microservice

---

## Services Using pf-common

- **pf-payroll** - Chilean payroll microservice (port 8000)
- **pf-rates** - Financial reference data (port 8001)
- **Future services** - Any new FastAPI microservice

**NOT used by:**
- **pf-db** - Database repository (different structure)

---

## Available Make Targets

See [make/README.md](make/README.md) for complete documentation.

**Quick reference:**

- `make install` - Create venv, install deps
- `make test` - Run pytest suite
- `make test-cov` - Run with 100% coverage requirement
- `make check` - Run all quality gates
- `make lint` - Ruff linter + formatter
- `make dead-code` - Vulture dead code detection
- `make typecheck` - mypy type checking
- `make duplicate-code` - jscpd duplication detection
- `make security-scan` - Trivy security scan
- `make run` - Start FastAPI server
- `make clean` - Remove artifacts

---

## Validation Script

**sync_deps.py** - Validates that core dependencies are synchronized:

```bash
python pf-common/scripts/sync_deps.py
# Output: "All 15 core dependencies are synchronized"
```

Add to CI pipeline:

```yaml
- name: Check dependency sync
  run: python pf-common/scripts/sync_deps.py
```

---

## Maintenance

### Adding New Targets

1. Edit `make/common.mk`
2. Document in `make/README.md`
3. Test with existing services (pf-payroll, pf-rates)
4. Commit with clear description

### Modifying Existing Targets

1. Check impact on services using pf-common
2. Maintain backward compatibility if possible
3. Update documentation
4. Test thoroughly
5. Communicate breaking changes

---

## Version History

- **v1.0.0** (2026-07-24) - Initial release
  - common.mk with all shared targets
  - sync_deps.py validation script
  - Complete documentation

---

## License

Same as parent PF ecosystem project.

---

## Questions?

- **Usage questions:** See [make/README.md](make/README.md)
- **Contributing:** Submit PR with clear description
- **Issues:** Open issue in pf-common repository

---

## See Also

- [make/README.md](make/README.md) - Detailed usage guide
- [make/templates/service.mk](make/templates/service.mk) - Template for new services
- [../ARCHITECTURE.md](../ARCHITECTURE.md) - PF ecosystem overview (if exists)
