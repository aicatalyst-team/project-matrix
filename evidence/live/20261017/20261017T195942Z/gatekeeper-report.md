# Project Matrix: Gatekeeper run

- Run: `20261017T195942Z`
- Layer: Gateway
- Code name: Gatekeeper
- Lane: `production`
- Profile: `gateway-production`
- Catalog: `2026-10-16`
- Support boundary: Production candidate: only release-gated and customer-supported capabilities may pass.
- Started: `2026-10-17T19:59:43Z`

This report is evidence for the selected lane. It does not make a production
claim when Technology Preview, workaround, partner, community, or demo-only
dependencies are present.

## Profile contract

- Required capabilities: `gateway.mcp-edge,gateway.maas-control-plane,gateway.oidc-policy`
- Optional capabilities: `gateway.external-model,lens.maas-telemetry`
- Cluster-wide mutations allowed: `false`
- GPU provisioning allowed: `false`

## Preflight

[2026-10-17T19:59:43Z] Profile contract: gateway-production (2026-10-16)
[2026-10-17T19:59:43Z] Required capabilities: gateway.mcp-edge,gateway.maas-control-plane,gateway.oidc-policy
[2026-10-17T19:59:43Z] OpenShift identity: kube:admin
[2026-10-17T19:59:43Z] OpenShift server: https://api.ocp-gb.ibm.redhataicatalyst.com:6443
Client Version: 4.20.3
Kustomize Version: v5.6.0
Server Version: 4.21.8
Kubernetes Version: v1.34.5
[2026-10-17T19:59:45Z] PASS: namespace mcp-gateway-system exists
[2026-10-17T19:59:46Z] PASS: namespace mempalace exists
[2026-10-17T19:59:46Z] PASS: CRD gateways.gateway.networking.k8s.io is installed
[2026-10-17T19:59:47Z] PASS: CRD httproutes.gateway.networking.k8s.io is installed
[2026-10-17T19:59:48Z] PASS: CRD mcpserverregistrations.mcp.kuadrant.io is installed
[2026-10-17T19:59:49Z] PASS: OpenShift AI DataScienceCluster/default-dsc: Ready
[2026-10-17T19:59:50Z] PASS: Gateway/mcp-gateway exists
[2026-10-17T19:59:51Z] FAIL: ingress ClusterOperator is Degraded: Package servicemeshoperator from subscription openshift-operators/servicemeshoperator prevents enabling operator-managed Gateway API. Uninstall openshift-operators/servicemeshoperator to enable functionality.
  mcp-gateway.v0.7.1                      MCP Gateway Operator (Tech Preview)           0.7.1      mcp-gateway.v0.7.0                      Succeeded
  servicemeshoperator.v2.6.17             Red Hat OpenShift Service Mesh 2              2.6.17-0   servicemeshoperator.v2.6.16             Succeeded
  servicemeshoperator3.v3.4.1             Red Hat OpenShift Service Mesh 3              3.4.1      servicemeshoperator3.v3.4.0             Succeeded
[2026-10-17T19:59:53Z] FAIL: preview/external Gateway dependency detected in production lane
[2026-10-17T19:59:53Z] FAIL: production lane requires GATEKEEPER_OIDC_ISSUER
[2026-10-17T19:59:53Z] Preflight result: failures=3, warnings=0
