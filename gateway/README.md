# PF API Gateway facade

This directory contains the reviewed OpenAPI inputs for the GCP API Gateway proof of
concept described by IMP-016.

## Current gateway

```text
https://pf-backend-gateway-poc-88uq0qjn.uc.gateway.dev
```

The facade routes `/reference/*` and `/income/*` through `pf-gateway-proxy` to the
corresponding Cloud Run service. Direct Cloud Run URLs remain rollback paths.

## Current proof of concept

`openapi/pf-gateway-health.yaml` exposes health and one read-only route per backend:

```text
GET /reference/health
GET /income/health
GET /reference/monetary-units
GET /income/payroll
```

The approved migration config uses the generated `gateway.dev` hostname and keeps the
health operations keyless. Business operations use native Google API Gateway API-key
security with the `X-Gateway-API-Key` header. API Gateway forwards original headers, so
`pf-gateway-proxy` removes that gateway-owned header before backend forwarding;
application `X-API-Key` remains a temporary compatibility header until backend services
stop requiring it. Direct Cloud Run URLs remain IAM-protected rollback paths.

The backend service account used by API Gateway must have only the required
`roles/run.invoker` permissions. Do not add API keys, credentials, or tokens to this
repository. The gateway configuration uses an explicit 30-second backend deadline for
this health/read-only proof of concept. It is a facade proof of concept, not authorization
to lock down direct Cloud Run invocation.

## Cost and rollout

The gateway is intended for `us-central1`, matching the Cloud Run services. Confirm
current API Gateway pricing, shared billing-account free-tier usage, and egress before
expanding the facade. The OpenAPI 2.0 `x-google-backend.deadline` is explicitly set to
30 seconds. Keep the proof of concept bounded until routing, IAM, response headers,
request correlation, and rollback are evidenced.
