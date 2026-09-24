# secrets/ (pf-common, local-only)

Module-scoped, machine-local secrets for `pf-common`. Everything placed in
this folder — including new subfolders — is gitignored by default (see
`.gitignore` right here): only this `README.md` and the `.gitignore` itself
can ever be committed.

## Currently unused, and that's fine

`pf-common` is shared build/Make infrastructure (`make/`, `scripts/`) with
no application code and no credentials of its own — every value it touches
(`PF_DATABASE_URL`, `[SERVICE]_API_KEY`, etc.) is passed in by the *calling*
service's own Makefile/environment, not stored here.

This folder exists purely for consistency with the other modules in this
ecosystem, and as the sanctioned landing spot in case a future script under
`scripts/` (e.g. `sync_deps.py`) ever needs a local, machine-specific
credential — a registry token for a manual publish test, for example.

## Rules

- If you add a real secret here, document it in this README (path, purpose,
  which script consumes it) so this file stops being a stub.
- Never hardcode a path to a file here inside committed code — read it from
  an environment variable.
