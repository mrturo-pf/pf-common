#!/usr/bin/env bash
# Shared helpers for the per-service "start everything locally" entrypoint
# (scripts/local_stack.sh in pf-rates/pf-payroll, wired to `make local-up`).
#
# Each service keeps its own local_stack.sh -- only the parts that were
# byte-for-byte identical across services (or should be, but had drifted)
# live here, so a future edit to one of them can't silently stop matching
# the other.
#
# Usage:
#   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#   source "$SCRIPT_DIR/../../pf-common/scripts/local_stack_common.sh"
#   pf_require_db_container "$DB_CONTAINER"
#   pf_ensure_venv "$VENV" "import rates, fastapi, uvicorn"
#   pf_print_startup_banner "$APP_PORT" "$ENV_FILE"

_pf_local_stack_common_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./detect_container_cli.sh
source "$_pf_local_stack_common_dir/detect_container_cli.sh"

pf_log() {
  printf '[local-up] %s\n' "$1"
}

# pf_require_db_container <container-name> -- exits 1 with a friendly
# message (pointing at `cd ../pf-db && make db-up`) if the shared pf-db
# container isn't running.
pf_require_db_container() {
  local container="$1"
  pf_log "Checking shared pf-db container ($container)"
  if ! container_is_running "$container"; then
    echo ""
    echo "ERROR: pf-db container '$container' is not running."
    echo ""
    echo "Start the shared database first:"
    echo "  cd ../pf-db && make db-up"
    echo ""
    exit 1
  fi
  pf_log "pf-db container is running"
}

# pf_ensure_venv <venv-dir> <python-import-check> -- reuses the venv if it
# already has a working interpreter/uvicorn and can import everything in
# <python-import-check> (e.g. "import rates, fastapi, uvicorn"); otherwise
# creates it and installs the package with its [dev] extras.
pf_ensure_venv() {
  local venv="$1"
  local import_check="$2"
  if [[ -x "$venv/bin/python" ]] && [[ -x "$venv/bin/uvicorn" ]] && \
     "$venv/bin/python" -c "$import_check" >/dev/null 2>&1; then
    pf_log "Reusing existing virtual environment in $venv"
    return 0
  fi
  pf_log "Installing project dependencies"
  if [[ ! -x "$venv/bin/python" ]]; then
    python3 -m venv "$venv"
  fi
  "$venv/bin/python" -m ensurepip --upgrade
  "$venv/bin/python" -m pip install -e ".[dev]"
}

# pf_print_startup_banner <app-port> <env-file> -- the final "you're ready"
# banner printed right before exec-ing uvicorn. Shared so every service
# shows the same 3 lines (API/Docs/Env), not whatever subset one script
# happened to have last time someone copy-pasted it.
pf_print_startup_banner() {
  local app_port="$1"
  local env_file="$2"
  printf '\n'
  printf 'API  : http://127.0.0.1:%s\n' "$app_port"
  printf 'Docs : http://127.0.0.1:%s/docs\n' "$app_port"
  printf 'Env  : %s\n' "$env_file"
  printf '\n'
}
