# Plan: Cloud Run observability and capacity

Date: 2026-10-12
Status: investigating
Level: M
Scope: Cheapest viable Cloud Run observability, capacity, probe, and database connection-budget baseline for PF services.
Related artifacts: [investigation](../investigations/cloud-run-observability-and-capacity.md) · [brief](cloud-run-observability-and-capacity-brief.md) · [recommendation](cloud-run-observability-and-capacity-recommendation.md)
Approved: pending explicit owner approval
Superseded-by: none

## 1. Gates

- [x] Initial evidence boundary and cost constraint recorded.
- [ ] Brief and recommendation approved.
- [ ] Current reusable workflow and service settings inventoried.
- [ ] Health/probe semantics validated for both services.
- [ ] Database connection budget agreed with `pf-db`.
- [ ] Alert ownership and thresholds approved.
- [ ] Per-service synthetic validation passed.
- [ ] Shared default changes, if any, released with rollback evidence.

## 2. Implementation slices

### Slice 1 — Runtime inventory

Record current Cloud Run settings, workflow inputs, health endpoints, pool sizes,
timeouts, concurrency, max instances, and existing Cloud Monitoring signals.

### Slice 2 — Capacity model

Calculate the connection upper bound for each service and compare it with the
approved PostgreSQL budget, including deployment overlap and operational headroom.

### Slice 3 — Probe and signal validation

Exercise startup, health, dependency failure, timeout, scaling, and representative
request scenarios with synthetic data. Define only actionable alerts.

### Slice 4 — Adoption decision

Apply changes to shared defaults only after both services pass validation. Preserve
scale-to-zero and document rollback for every setting change.

## 3. Change log

| Date | Status | Change | Evidence |
|---|---|---|---|
| 2026-10-12 | investigating | Promoted IMP-007 to formal artifacts; no workflow or Cloud Run mutation. | Register and shared deployment constraints |

## 4. Release record

- Commits: pending
- Workflow runs: pending
- Owner approval: pending
- Service validation: pending
- Rollback evidence: pending
