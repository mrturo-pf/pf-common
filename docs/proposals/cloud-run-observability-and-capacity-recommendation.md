# Recommendation: Cloud Run observability and capacity

Date: 2026-10-12
Status: designed
Level: M
Scope: Cheapest viable Cloud Run observability, capacity, probe, and database connection-budget baseline for PF services.
Related artifacts: [brief](cloud-run-observability-and-capacity-brief.md) · [investigation](../investigations/cloud-run-observability-and-capacity.md) · [plan](cloud-run-observability-and-capacity-plan.md) · [register](../../../docs/proposals/ecosystem-improvement-register.md)
Approved: pending explicit owner approval
Superseded-by: none

## 1. Recommendation

Adopt a four-part baseline:

1. **Health:** separate process/startup readiness from dependency checks; document
   which endpoint each probe uses and what failure means.
2. **Capacity:** retain scale-to-zero, bounded max instances, explicit timeout,
   concurrency, CPU, and memory settings; change defaults only with measured
   evidence.
3. **Database budget:** calculate `max_instances × pool_size × connection factor`
   against the approved PostgreSQL budget before release. Include migration jobs and
   operational headroom.
4. **Signals:** use existing Cloud Run/Cloud Monitoring request count, latency,
   4xx/5xx, instance count, and revision health signals first. Add custom alerts only
   when an actionable gap is demonstrated.

## 2. Minimum operational record

Each service release records revision, region, resource settings, probe behavior,
observed latency/error outcomes, database pool settings, calculated connection
upper bound, alert ownership, and rollback decision. No secrets or raw payloads.

## 3. Rejected alternatives

- Always-on instances: rejected because scale-to-zero is the ecosystem default and
  traffic does not justify the standing cost without evidence.
- Unlimited max instances: rejected because it can exhaust database connections.
- Paid third-party monitoring before baseline validation: rejected as premature.
- One generic health check for every dependency: rejected because readiness and
  dependency failure have different operational meanings.

## 4. Decision gate

Approve the baseline, connection-budget formula, and per-service validation matrix.
Shared workflow defaults remain unchanged until both services pass the matrix.
