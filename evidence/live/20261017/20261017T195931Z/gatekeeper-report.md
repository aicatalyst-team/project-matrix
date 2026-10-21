# Project Matrix: Gatekeeper run

- Run: `20261017T195931Z`
- Layer: Gateway
- Code name: Gatekeeper
- Lane: `innovation`
- Profile: `gateway-evaluation`
- Catalog: `2026-10-16`
- Support boundary: Innovation lane: Technology Preview, Developer Preview, partner, demo, and explicitly bounded evaluation capabilities.
- Started: `2026-10-17T19:59:31Z`

This report is evidence for the selected lane. It does not make a production
claim when Technology Preview, workaround, partner, community, or demo-only
dependencies are present.

## Profile contract

- Required capabilities: `gateway.mcp-edge,gateway.maas-control-plane`
- Optional capabilities: `gateway.oidc-policy,gateway.external-model,bastion.oidc-fixture,ember-flux.evaluation-backend,lens.maas-telemetry`
- Cluster-wide mutations allowed: `false`
- GPU provisioning allowed: `false`

## Preflight

[2026-10-17T19:59:31Z] Profile contract: gateway-evaluation (2026-10-16)
[2026-10-17T19:59:31Z] Required capabilities: gateway.mcp-edge,gateway.maas-control-plane
[2026-10-17T19:59:32Z] OpenShift identity: kube:admin
[2026-10-17T19:59:32Z] OpenShift server: https://api.ocp-gb.ibm.redhataicatalyst.com:6443
Client Version: 4.20.3
Kustomize Version: v5.6.0
Server Version: 4.21.8
Kubernetes Version: v1.34.5
[2026-10-17T19:59:34Z] PASS: namespace mcp-gateway-system exists
[2026-10-17T19:59:34Z] PASS: namespace mempalace exists
[2026-10-17T19:59:35Z] PASS: CRD gateways.gateway.networking.k8s.io is installed
[2026-10-17T19:59:36Z] PASS: CRD httproutes.gateway.networking.k8s.io is installed
[2026-10-17T19:59:36Z] PASS: CRD mcpserverregistrations.mcp.kuadrant.io is installed
[2026-10-17T19:59:38Z] PASS: OpenShift AI DataScienceCluster/default-dsc: Ready
[2026-10-17T19:59:39Z] PASS: Gateway/mcp-gateway exists
[2026-10-17T19:59:40Z] WARN: ingress ClusterOperator is Degraded: Package servicemeshoperator from subscription openshift-operators/servicemeshoperator prevents enabling operator-managed Gateway API. Uninstall openshift-operators/servicemeshoperator to enable functionality.
  mcp-gateway.v0.7.1                      MCP Gateway Operator (Tech Preview)           0.7.1      mcp-gateway.v0.7.0                      Succeeded
  servicemeshoperator.v2.6.17             Red Hat OpenShift Service Mesh 2              2.6.17-0   servicemeshoperator.v2.6.16             Succeeded
  servicemeshoperator3.v3.4.1             Red Hat OpenShift Service Mesh 3              3.4.1      servicemeshoperator3.v3.4.0             Succeeded
[2026-10-17T19:59:42Z] WARN: Gateway dependency set includes preview or externally managed components
[2026-10-17T19:59:42Z] WARN: OIDC issuer is not configured; innovation profile will not apply native AuthPolicy
[2026-10-17T19:59:42Z] Preflight result: failures=0, warnings=3
[2026-10-17T19:59:42Z] Evidence directory: /tmp/project-matrix-live-runs/20261017T195931Z
