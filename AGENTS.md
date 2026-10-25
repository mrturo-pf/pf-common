# AGENTS.md — pf-common

Shared infrastructure for the PF ecosystem: reusable Make targets, shell helpers,
validation scripts, and templates consumed by PF services. This repository is not a
deployable service and has no HTTP API or database ownership.

## Scope

This file governs implementation, testing, documentation, and operations inside
`pf-common`. Ecosystem ownership boundaries and cross-repository coordination are
defined in the root [`AGENTS.md`](../../AGENTS.md). This file owns the shared-tooling
details.

## Repository responsibilities

`pf-common` owns reusable infrastructure that is intentionally consumed by more than
one repository:

- `make/common.mk` and service Makefile templates;
- shell helpers under `scripts/`;
- dependency and configuration validation utilities;
- documentation for integrating the shared targets and helpers.

The primary consumers are `pf-rates` and `pf-svc-income`. Keep shared code generic;
service-specific business logic belongs in the consuming service repository.

## Architecture and design

- Make targets provide defaults that consuming repositories can override explicitly.
- Shell helpers expose small, composable functions and must not assume a particular
  service's application module, database schema, or deployment URL.
- Shared scripts validate inputs and fail clearly; never hide errors with silent
  fallbacks or broad exception suppression.
- Keep dependency direction one-way: consuming services may use `pf-common`, but
  `pf-common` must not import application code or private configuration from them.
- Prefer the smallest reusable abstraction that solves a demonstrated cross-service
  need. Do not add shared machinery for a single caller.

## Quality and compatibility

Changes to shared infrastructure are potentially cross-repository changes:

1. Identify every current consumer before changing a shared target or helper.
2. Preserve existing target names, function names, environment variables, and exit
   codes unless a migration path is documented.
3. Add or update executable validation for behavioral changes.
4. Run the relevant checks in `pf-rates` and `pf-svc-income` before delivery when the
   change affects their build, test, local-stack, or deployment workflow.
5. Update this README or the focused documentation when integration behavior changes.

Documentation-only, formatting-only, and mechanical refactors do not require new
tests, but applicable validation must still run.

## Development commands

This repository has no application installation or runtime. Its Makefile only
configures the repository's Git hooks:

```bash
make install
```

Useful validations include:

```bash
python3 scripts/sync_deps.py
bash -n scripts/*.sh
python3 -m py_compile scripts/*.py
```

Run commands from this repository unless a script's documentation says otherwise.
When a shared change affects a consumer, run that consumer's documented `make check`
(or the narrowest applicable target) as well.

## Language and style

- Code, identifiers, comments, docstrings, and documentation are English.
- Preserve official Chilean regulatory terms and source literals when translation
  would change their meaning.
- Use clear POSIX shell where portability permits; use Bash-specific features only
  when the script explicitly declares Bash.
- Quote shell paths and variables. Use `set -euo pipefail` in executable Bash
  scripts unless the script has a documented reason not to.
- Use SemVer and Conventional Commits in English.
- Keep files cohesive and avoid duplicating constants, commands, or integration
  rules across templates and scripts.

## Security and secrets

- Never commit API keys, passwords, tokens, connection strings, personal data,
  payroll data, or production payloads.
- Files under `secrets/` are templates or local-only material; inspect their contents
  before adding or changing them.
- Shared scripts must not print secret values or copy secrets into generated files.
- Runtime credentials belong to the consuming service's approved secret-management
  workflow, not to this repository.

## Cost and operational safety

Cloud cost is always the priority for shared deployment helpers: prefer scale-to-zero,
free scanning and on-demand resources over always-on or paid alternatives. Any change
affecting deployment templates must state its cost and compatibility impact in the
change documentation.

Do not change database schemas, service APIs, or deployment ownership here as a local
workaround. Coordinate those changes with the owning repository and update all
consumers at the integration boundary.

## Git and GitHub operations

- Work on a dedicated branch and submit changes through the repository's documented
  review workflow.
- Never commit, push, create branches, issues, or pull requests autonomously unless
  the owner explicitly requests it.
- Before any GitHub interaction using `gh`, run:

  ```bash
  source "$HOME/Documents/scripts/unset_proxies.sh"
  ```

- Never bypass TLS verification or expose credentials in commands or logs.

## Related documentation

- [`README.md`](README.md) — shared infrastructure overview and integration examples.
- [`make/README.md`](make/README.md) — shared Make targets and templates.
- [`scripts/`](scripts/) — helper implementations and script-specific guidance.
- Root [`AGENTS.md`](../../AGENTS.md) — ecosystem ownership and cross-repository rules.
