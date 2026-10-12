# Investigation: Cloud Run observability and capacity

Date: 2026-10-12
Status: investigating
Level: M
Scope: Establish the cheapest viable Cloud Run observability, probe, scaling, concurrency, and database connection-budget baseline for PF services.
Owner: `pf-common`
Related artifacts: [brief](../proposals/cloud-run-observability-and-capacity-brief.md) · [recommendation](../proposals/cloud-run-observability-and-capacity-recommendation.md) · [plan](../proposals/cloud-run-observability-and-capacity-plan.md) · [register](../../../docs/proposals/ecosystem-improvement-register.md)
Superseded-by: none

## 1. Question

What minimum Cloud Run operational baseline protects `pf-rates` and `pf-payroll`
from silent availability, capacity, and database-connection failures without
introducing unnecessary paid infrastructure?

## 2. Evidence boundary

The baseline must cover the shared reusable deployment workflow and its consumers:

- health/readiness behavior and probe semantics;
- min/max instances, concurrency, CPU/memory, timeout, and scale-to-zero;
- Cloud Run request/error/latency signals;
- database connection pool sizing against the shared PostgreSQL budget;
- rollback and release evidence.

The investigation must use sanitized metadata and synthetic load. It must not record
credentials, raw request payloads, personal/financial data, or database contents.

## 3. Initial findings and questions

- The ecosystem favors `min-instances=0`, bounded max instances, and free existing
  tooling before paid monitoring.
- A service-level max-instance setting is not sufficient unless the aggregate
  database connection budget is explicit.
- Health checks must distinguish process readiness from dependency availability;
  otherwise deployments can either admit broken revisions or block unnecessarily.
- Alerts should begin with existing Cloud Run/Cloud Monitoring signals and only add
  custom metrics when a concrete gap is demonstrated.

Open questions:

1. What connection budget is approved for each service and deployment size?
2. Which health endpoint is suitable for startup/readiness versus liveness?
3. Which latency/error thresholds are meaningful for the current traffic profile?
4. Which alerts are actionable enough to justify operational ownership?

## 4. Current conclusion

Create a shared operational baseline and validate it per service before changing
workflow defaults. Do not provision always-on capacity or paid dashboards merely to
close this investigation.
