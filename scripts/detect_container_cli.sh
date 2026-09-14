#!/usr/bin/env bash
# Shared helper: detect which container CLI can actually see a given
# container by name, and report whether it's running.
#
# On macOS Rancher Desktop, containers started via `docker compose` may
# live under nerdctl/containerd rather than the moby "docker" engine --
# `docker inspect` returns "no such object" for them even though they are
# genuinely running. pf-db/Makefile already solves this for its own
# `docker compose`/build usage by preferring nerdctl when available; this
# script gives the same detection to plain bash scripts (like
# scripts/local_stack.sh in pf-rates/pf-payroll) that only need to check
# "is container X running?", not manage containers themselves.
#
# Usage:
#   source "../../pf-common/scripts/detect_container_cli.sh"
#   if ! container_is_running "$DB_CONTAINER"; then ...; fi

_pf_container_cli_candidates() {
  printf '%s\n' \
    "docker" \
    "nerdctl" \
    "$HOME/.rd/bin/nerdctl" \
    "$HOME/.rd/bin/nerdctl --address /var/run/docker/containerd/containerd.sock"
}

# container_is_running <name> -- returns 0 (true) if any known container
# CLI reports the named container as running, 1 (false) otherwise.
container_is_running() {
  local name="$1"
  local cli status
  while IFS= read -r cli; do
    # shellcheck disable=SC2086 -- $cli intentionally expands to "bin --flag"
    # Stdin is explicitly redirected to /dev/null: without it, a failing
    # nerdctl/docker invocation can read from (and drain) the very pipe
    # this while-read loop is consuming its candidates from, silently
    # skipping the remaining candidates after the first failure.
    status=$($cli inspect --format '{{.State.Status}}' "$name" </dev/null 2>/dev/null) || continue
    if [[ "$status" == "running" ]]; then
      return 0
    fi
  done < <(_pf_container_cli_candidates)
  return 1
}
