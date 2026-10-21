# Project Matrix: Gatekeeper run

- Run: `20261017T200021Z`
- Layer: Gateway
- Code name: Gatekeeper
- Lane: `innovation`
- Profile: `gateway-evaluation`
- Catalog: `2026-10-16`
- Support boundary: Innovation lane: Technology Preview, Developer Preview, partner, demo, and explicitly bounded evaluation capabilities.
- Started: `2026-10-17T20:00:22Z`

This report is evidence for the selected lane. It does not make a production
claim when Technology Preview, workaround, partner, community, or demo-only
dependencies are present.

## Profile contract

- Required capabilities: `gateway.mcp-edge,gateway.maas-control-plane`
- Optional capabilities: `gateway.oidc-policy,gateway.external-model,bastion.oidc-fixture,ember-flux.evaluation-backend,lens.maas-telemetry`
- Cluster-wide mutations allowed: `false`
- GPU provisioning allowed: `false`

## Evaluate

Aramock Gateway conformance (read-only)
Model: aramock-models/aramock-simulator
MaaS governance: models-as-a-service/aramock-simulator-free
WARN: Aramock fixture is not installed; no fixture resources were changed or created
Aramock conformance result: failures=0 warnings=1
[2026-10-17T20:00:26Z] WARN: Aramock fixture is not fully present; conformance remains advisory
[2026-10-17T20:00:26Z] WARN: live MCP-to-MaaS evaluation not selected; set GATEKEEPER_ROUNDTRIP=1
[2026-10-17T20:00:26Z] Reference task: Summarize the current MCP gateway architecture using live cluster and memory observations.
[2026-10-17T20:00:26Z] Evidence directory: /tmp/project-matrix-live-runs/20261017T200021Z
