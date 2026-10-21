# Gatekeeper upgrade compatibility evidence — 2026-10-18

This is a read-only compatibility observation for the target OpenShift AI
instance. No InstallPlan was approved and no OpenShift/OpenShift AI upgrade was
performed by Project Matrix.

## Current baseline

- OpenShift: `4.21.8`, channel `stable-4.21`
- OpenShift AI operator: `3.5.0`, `rhods-operator` Subscription in
  `redhat-ods-operator`
- OpenShift AI Subscription: channel `stable-3.x`, approval `Manual`
- DataScienceCluster: `default-dsc`, `Ready`
- MCP Gateway: `0.7.1`, `preview` channel / Technology Preview
- Gateway: Accepted and Programmed; HTTPS and DNSRecord Published
- Backend isolation: effective AdminNetworkPolicy gate passes
- ClusterOperators: Available, not Degraded, not Progressing at capture time

## Customer-controlled upgrade state

The cluster exposes a manual-approval InstallPlan for a future OpenShift AI
operator version (`rhods-operator.3.5.1`) and other manual-approval plans for
related operators. Gatekeeper reports those plans as warnings. They do not block
use of a compatible current baseline, and Gatekeeper does not approve them.

## Decision

The current-instance path is valid as the default lifecycle. The Gateway
Production claim remains blocked by the separately qualified MCP Gateway
Technology Preview dependency and the native OIDC AuthPolicy HTTP 500/401
compatibility defect. The Preview/Innovation lane passes its preflight with
those boundaries explicitly disclosed.

The machine-readable capture is produced by:

```bash
./gatekeeper/gatekeeper.sh --profile innovation upgrade-preflight
```

The post-upgrade promotion gate is:

```bash
GATEKEEPER_UPGRADE_BASELINE=/path/to/upgrade-baseline.json \
  ./gatekeeper/gatekeeper.sh --profile production upgrade-postcheck
```
