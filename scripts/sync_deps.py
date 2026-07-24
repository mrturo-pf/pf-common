#!/usr/bin/env python3
"""Validate that core dependencies are synchronized between pf-payroll and pf-rates.

This script ensures that critical shared dependencies (FastAPI, SQLAlchemy, pytest, etc.)
are at the same minimum version across all FastAPI microservices in the PF ecosystem.

Usage:
    python pf-common/scripts/sync_deps.py

Exit codes:
    0 - All core dependencies are synchronized
    1 - Mismatches detected

Core dependencies checked:
    - asyncpg, fastapi, greenlet, pydantic, pydantic-settings
    - sqlalchemy, structlog, uvicorn
    - mypy, pytest, pytest-asyncio, pytest-cov
    - ruff, testcontainers, vulture
"""

import sys
import tomllib
from pathlib import Path

# Core dependencies that MUST be synchronized across services
CORE_DEPS = {
    "asyncpg",
    "fastapi",
    "greenlet",
    "pydantic",
    "pydantic-settings",
    "sqlalchemy",
    "structlog",
    "uvicorn",
    "mypy",
    "pytest",
    "pytest-asyncio",
    "pytest-cov",
    "ruff",
    "testcontainers",
    "vulture",
}


def extract_deps(toml_path: Path) -> dict[str, str]:
    """Extract core dependencies from pyproject.toml."""
    with open(toml_path, "rb") as f:
        data = tomllib.load(f)

    deps = {}

    # Extract from [project.dependencies]
    for dep in data.get("project", {}).get("dependencies", []):
        name = dep.split(">=")[0].split("[")[0].strip()
        if name in CORE_DEPS:
            deps[name] = dep

    # Extract from [project.optional-dependencies.dev]
    dev_deps = data.get("project", {}).get("optional-dependencies", {}).get("dev", [])
    for dep in dev_deps:
        name = dep.split(">=")[0].split("[")[0].strip()
        if name in CORE_DEPS:
            deps[name] = dep

    return deps


def main() -> int:
    """Main entry point."""
    # Paths to pyproject.toml files
    repo_root = Path(__file__).parent.parent.parent
    payroll_toml = repo_root / "pf-payroll" / "pyproject.toml"
    rates_toml = repo_root / "pf-rates" / "pyproject.toml"

    # Check files exist
    if not payroll_toml.exists():
        print(f"ERROR: {payroll_toml} not found")
        return 1
    if not rates_toml.exists():
        print(f"ERROR: {rates_toml} not found")
        return 1

    # Extract dependencies
    payroll_deps = extract_deps(payroll_toml)
    rates_deps = extract_deps(rates_toml)

    # Find mismatches
    mismatches = []
    for dep in sorted(CORE_DEPS):
        payroll_ver = payroll_deps.get(dep)
        rates_ver = rates_deps.get(dep)

        if payroll_ver != rates_ver:
            # At least one has it defined, but they differ
            if payroll_ver or rates_ver:
                mismatches.append(
                    (dep, payroll_ver or "MISSING", rates_ver or "MISSING")
                )

    # Report results
    if mismatches:
        print("ERROR: Core dependencies differ between pf-payroll and pf-rates:")
        print()
        for dep, payroll_ver, rates_ver in mismatches:
            print(f"  {dep}:")
            print(f"    pf-payroll: {payroll_ver}")
            print(f"    pf-rates:   {rates_ver}")
        print()
        print(
            f"Found {len(mismatches)} mismatch(es) out of {len(CORE_DEPS)} core dependencies."
        )
        return 1
    else:
        print(
            f"All {len(CORE_DEPS)} core dependencies are synchronized between pf-payroll and pf-rates"
        )
        return 0


if __name__ == "__main__":
    sys.exit(main())
