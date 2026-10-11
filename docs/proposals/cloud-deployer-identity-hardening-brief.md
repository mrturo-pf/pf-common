# Brief: Cloud deployer identity hardening

Date: 2026-10-11
Status: approved
Level: L
Scope: Reusable identity separation and least-privilege deployment model for PF GitHub Actions, Cloud Run, database migrations, and administration.
Related artifacts: [investigation](../investigations/cloud-deployer-identity-hardening.md) · [register](../../../docs/proposals/ECOSYSTEM-IMPROVEMENT-REGISTER.md) · [index](../../../docs/proposals/INDEX.md)
Approved: 2026-10-11 by owner (conversation)
Superseded-by: none

## Objective

Establish a reusable, least-privilege identity model for the PF ecosystem that
separates:

- GitHub Actions authentication and deployment;
- Cloud Run runtime identities for each service;
- database migration identity;
- backup/restore identity;
- human administration and emergency access.

Evaluate and, when feasible, adopt GitHub Actions OIDC with Google Workload
Identity Federation instead of long-lived service-account JSON keys. Preserve
manual production approval, migration-before-traffic ordering, rollback, and
service-specific Secret Manager access.

## Non-objectives

- Applying IAM changes, creating or deleting service accounts, or revoking keys
  before the recommendation is explicitly approved;
- changing application behavior or public HTTP contracts;
- redesigning database table grants owned by `pf-db`;
- replacing the existing production approval process without an explicit decision;
- exposing secret values, private keys, access tokens, or production data.

## Affected repositories and ownership

| Responsibility | Owner |
| --- | --- |
| Reusable authentication/deployment workflows and shared actions | `pf-common` |
| Ecosystem coordination and release gates | `pf-base` |
| Database migration identity and schema compatibility | `pf-db` |
| Rates runtime identity and service deployment consumer | `pf-rates` |
| Payroll runtime identity and service deployment consumer | `pf-payroll` |

## Current evidence

The investigation also confirmed in the owner-approved GCP project that
`pf-rates` and `pf-payroll` have separate Cloud Run runtime accounts, each with a
user-managed key, while no Workload Identity Federation pool or provider exists.
Both runtime accounts currently have project-level deployment permissions that
must be evaluated against their runtime needs. The GitHub secret-to-account
mapping and organization policy for WIF remain open.


## Required outcomes

- Every service has a distinct runtime identity with only its runtime permissions.
- CI deployer identities cannot be used as runtime identities and cannot receive
  unnecessary database, secret, or administrative permissions.
- Database migration, backup, and human operator identities are separate from
  application runtime identities.
- GitHub Actions authentication does not require a long-lived private key when
  WIF is feasible; any temporary coexistence has an explicit sunset and rollback.
- IAM grants are resource-scoped where feasible and documented with owners.
- Secret Manager access is limited to the secrets required by each service.
- Production approval and migration-before-traffic gates remain intact.
- Rotation, revocation, rollback, and consumer smoke validation are executable
  and have named owners.
- No secret value or private key enters Git, logs, chat, or proposal artifacts.

## Constraints and invariants

- Cloud cost remains a priority; prefer existing GitHub/GCP capabilities over new
  always-on infrastructure.
- IAM mutations require explicit owner approval and must be idempotent or
  reversible where the provider permits it.
- The target GCP project, organization policy, GitHub environments, and existing
  identities must be confirmed before design approval.
- `pf-common` owns reusable workflow behavior; callers own repository-specific
  inputs and service owners validate runtime compatibility.
- The source of truth for deployment behavior is the workflow/action code plus
  the approved IAM matrix, not setup comments alone.

## Acceptance criteria

1. A sanitized live inventory identifies current deployer, runtime, migration,
   backup, and operator identities, key state, WIF state, and relevant bindings.
2. A recommendation compares WIF against the minimum viable key-based fallback,
   including blast radius, rollback, operational cost, and migration order.
3. The approved matrix maps each identity to allowed resources/actions and explicit
   exclusions for `pf-rates`, `pf-payroll`, and `pf-db`.
4. A plan defines staged preparation, validation, cutover, key retirement, and
   rollback without requiring simultaneous outage.
5. Workflows and shared actions validate authentication using synthetic or
   non-production checks before any production identity is changed.
6. Post-cutover checks prove deployment, runtime secret access, database migration
   ordering, and service health for each affected service.
7. Closure includes key inventory review, cleanup evidence, owner acceptance, and
   updated workflow/deployment documentation.

## Questions requiring decisions

- Is the currently configured local GCP project the target PF GCP project?
- Is GitHub Actions OIDC/WIF permitted by the organization and repository policy?
- Should there be one tightly scoped deployer per service or a shared deployer
  identity with explicit resource-level permissions?
- Which identity owns `pf-db` migrations against the production database?
- Which backup/restore and emergency operator identities already exist?
- What rollback window and sunset date are acceptable for any temporary key
  coexistence?
- Who approves IAM mutations, GitHub environment changes, and key retirement?

## Requested recommendation format

Return a decision record containing: recommended identity topology, WIF design,
resource-scoped IAM matrix, secret access matrix, migration/rollback sequence,
validation commands and expected results, cost impact, rejected alternatives,
owner approvals, and remaining blockers. Do not begin implementation from this
brief alone.
