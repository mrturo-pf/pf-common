#!/usr/bin/env bash
# Shared helper for the per-service scripts/write_env.sh (writes the local
# .env file consumed by `make local-up`).
#
# Usage (inside the `{ ... } > "$ENV_FILE"` block, after the
# service-specific lines):
#   pf_corporate_tooling_env_block "$CORPORATIVE_PIP_INDEX" \
#     "$CORPORATIVE_NPM_REGISTRY" "$CORPORATIVE_PROXY"

# pf_corporate_tooling_env_block <pip-index> <npm-registry> <proxy> --
# prints the comment + 3 CORPORATIVE_* lines that are identical, verbatim,
# in every service's .env (used by `make install`/`make check` on VPN).
pf_corporate_tooling_env_block() {
  local pip_index="$1"
  local npm_registry="$2"
  local proxy="$3"
  printf '\n# Tooling — corporate pip/npm registries (used by make install/check on VPN)\n'
  printf 'CORPORATIVE_PIP_INDEX=%s\n' "$pip_index"
  printf 'CORPORATIVE_NPM_REGISTRY=%s\n' "$npm_registry"
  printf 'CORPORATIVE_PROXY=%s\n' "$proxy"
}
