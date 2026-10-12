# Brief: Cloud Run observability and capacity

Date: 2026-10-12
Status: investigating
Level: M
Scope: Cheapest viable Cloud Run observability, capacity, probe, and database connection-budget baseline for PF services.
Related artifacts: [investigation](../investigations/cloud-run-observability-and-capacity.md) · [recommendation](cloud-run-observability-and-capacity-recommendation.md) · [plan](cloud-run-observability-and-capacity-plan.md) · [register](../../../docs/proposals/ecosystem-improvement-register.md)
Approved: pending explicit owner approval
Superseded-by: none

## Objective

Define a reusable Cloud Run baseline for `pf-rates` and `pf-payroll` that preserves
scale-to-zero, limits capacity safely, detects actionable failures, and prevents
connection-pool settings from exceeding the shared database budget.

## Non-objectives

- Provisioning paid observability products by default;
- keeping minimum instances warm without measured need;
- redesigning service health APIs;
- changing deployment settings before per-service validation;
- recording secrets, payloads, or production personal data.

## Required outcomes

- Probe and health semantics;
- scaling, timeout, concurrency, and resource baseline;
- database connection-budget method;
- actionable alert and dashboard minimum;
- release and rollback evidence requirements.

## Acceptance criteria

1. Defaults are compatible with scale-to-zero and bounded cost.
2. Capacity settings are tied to an explicit database connection budget.
3. Alerts have an owner, threshold, evidence source, and action.
4. The baseline can be applied to both current Python services without hidden fallback.
5. Changes are validated before shared workflow defaults are modified.
