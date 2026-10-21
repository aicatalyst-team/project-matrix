# Project Matrix Gatekeeper — RHCL readiness gate

Date: 2026-10-19  
Cluster: `api.ocp-gb.ibm.redhataicatalyst.com`  
Scope: RHCL prerequisite inspection and scoped invalid-installation remediation

## Intended dependency

The pinned upstream MCP Gateway preview is `v1.0.2`. Its OpenShift deployment
requires RHCL `1.5.0+`. The Red Hat OLM-managed MCP Gateway remains a separate
baseline and was not changed.

## Live catalog and operator state

| Check | Result |
|---|---|
| RHCL catalog channels | `stable -> rhcl-operator.v1.4.3`; `stable-1.4 -> rhcl-operator.v1.4.4` |
| RHCL 1.5.0+ OLM candidate | **Absent** |
| Cluster-wide RHCL | `rhcl-operator.v1.4.2`, `Succeeded`, `global-operators` |
| Duplicate namespace-scoped RHCL | **Removed**: `mcp-gateway-system/rhcl-operator-stable-redhat-operators-openshift-marketplace` |
| Duplicate CSV remnants | **Removed**: failed `rhcl-operator.v1.4.2` and `rhcl-operator.v1.4.3` |

The failed CSVs reported: `OwnNamespace InstallModeType not supported, cannot
configure to watch own namespace`. RHCL supports only the AllNamespaces install
mode, so the namespace-scoped subscription was not a valid installation path.

## Gate behavior

`gatekeeper/rhcl/check-readiness.sh` returned:

```text
RHCL readiness: BLOCKED (1 gate failure(s))
```

The remaining failure is solely the absence of RHCL 1.5.0+ from the approved
catalog. The global RHCL CSV remains `1.4.2/Succeeded` under
`openshift-operators/global-operators`; the invalid duplicate subscription and
stale failed CSVs are no longer present.

The upstream installer was then run with explicit preview confirmation. It
returned exit code 1 before creating `mcp-gateway-preview`; the namespace
remained absent. No Subscription, InstallPlan, CSV, OperatorGroup, Gateway,
Route, or Helm release was modified.

## Required platform-owner actions

1. Publish or make available the approved RHCL 1.5.0+ OLM/catalog path.
2. Re-run the readiness gate and only then instantiate upstream MCP Gateway
   `v1.0.2` in its isolated preview namespace.

Project Matrix intentionally does not approve InstallPlans, alter Subscriptions,
delete OperatorGroups, or install an RHCL image outside OLM.
