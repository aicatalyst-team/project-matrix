# Project Matrix: Gatekeeper run

- Run: `20261017T200017Z`
- Layer: Gateway
- Code name: Gatekeeper
- Lane: `innovation`
- Profile: `gateway-evaluation`
- Catalog: `2026-10-16`
- Support boundary: Innovation lane: Technology Preview, Developer Preview, partner, demo, and explicitly bounded evaluation capabilities.
- Started: `2026-10-17T20:00:17Z`

This report is evidence for the selected lane. It does not make a production
claim when Technology Preview, workaround, partner, community, or demo-only
dependencies are present.

## Profile contract

- Required capabilities: `gateway.mcp-edge,gateway.maas-control-plane`
- Optional capabilities: `gateway.oidc-policy,gateway.external-model,bastion.oidc-fixture,ember-flux.evaluation-backend,lens.maas-telemetry`
- Cluster-wide mutations allowed: `false`
- GPU provisioning allowed: `false`

## Validate

[2026-10-17T20:00:18Z] PASS: Gateway/mcp-gateway: Accepted=True, Programmed=True
NAME            PREFIX   TARGET                PATH   READY   TOOLS   CATEGORY                                 CREDENTIALS   AGE
mempalace                mempalace-mcp-route   /mcp   True    29      ["memory","knowledge-management"]                      61d
openshift-mcp            openshift-mcp-route   /mcp   True    13      ["cluster-management","observability"]                 31d
[2026-10-17T20:00:20Z] PASS: MCP server registrations are queryable
[2026-10-17T20:00:20Z] PASS: backend bypass backstop resource is present
[2026-10-17T20:00:21Z] Unauthenticated MCP endpoint: https://<configured-host>/mcp -> HTTP 503
[2026-10-17T20:00:21Z] WARN: expected HTTP 401 from secured edge, received 503
[2026-10-17T20:00:21Z] WARN: positive authenticated MCP test skipped; GATEKEEPER_BEARER_TOKEN is not set and is never written to evidence
[2026-10-17T20:00:21Z] WARN: direct backend probe skipped; set GATEKEEPER_CONFIRM_NETWORK_PROBE=1 to create a temporary probe pod
[2026-10-17T20:00:21Z] Validation result: failures=0, warnings=3
[2026-10-17T20:00:21Z] Evidence directory: /tmp/project-matrix-live-runs/20261017T200017Z
