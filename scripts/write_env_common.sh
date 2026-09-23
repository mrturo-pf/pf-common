#!/usr/bin/env bash
# Shared helper for the per-service scripts/write_env.sh (writes the local
# .env file consumed by `make local-up`).
#
# Usage (inside the `{ ... } > "$ENV_FILE"` block, after the
# service-specific lines):
#   pf_corporate_tooling_env_block "$CORPORATIVE_PIP_INDEX" \
#     "$CORPORATIVE_NPM_REGISTRY" "$CORPORATIVE_PROXY"
#
# Each argument falls back to the real Walmart Artifactory/proxy endpoint
# when the caller passes an empty string (the common case: a service's
# write_env.sh does `CORPORATIVE_PIP_INDEX="${CORPORATIVE_PIP_INDEX:-}"`,
# i.e. blank unless the developer's shell already exports an override).
# `common.mk`'s `install`/`duplicate-code-*` targets probe
# CORPORATIVE_PIP_INDEX to auto-detect the Walmart VPN, so these defaults
# make that detection work out of the box instead of silently no-op'ing.

_PF_DEFAULT_CORPORATIVE_PIP_INDEX="https://pypi.ci.artifacts.walmart.com/artifactory/api/pypi/external-pypi/simple"
_PF_DEFAULT_CORPORATIVE_NPM_REGISTRY="https://npm.ci.artifacts.walmart.com/artifactory/api/npm/external-npm"
_PF_DEFAULT_CORPORATIVE_PROXY="http://sysproxy.wal-mart.com:8080"

# pf_corporate_tooling_env_block <pip-index> <npm-registry> <proxy> --
# prints the comment + 3 CORPORATIVE_* lines that are identical, verbatim,
# in every service's .env (used by `make install`/`make check` on VPN).
pf_corporate_tooling_env_block() {
  local pip_index="${1:-$_PF_DEFAULT_CORPORATIVE_PIP_INDEX}"
  local npm_registry="${2:-$_PF_DEFAULT_CORPORATIVE_NPM_REGISTRY}"
  local proxy="${3:-$_PF_DEFAULT_CORPORATIVE_PROXY}"
  printf '\n# Tooling — corporate pip/npm registries (used by make install/check on VPN)\n'
  printf 'CORPORATIVE_PIP_INDEX=%s\n' "$pip_index"
  printf 'CORPORATIVE_NPM_REGISTRY=%s\n' "$npm_registry"
  printf 'CORPORATIVE_PROXY=%s\n' "$proxy"
}
