# Gatekeeper upgrade and no-upgrade compatibility contract

Project Matrix: Gatekeeper must deliver value on the OpenShift AI instance the
customer already has. A customer is not required to upgrade OpenShift,
OpenShift AI, Service Mesh, or a Gateway dependency merely to use the Gateway
layer.

The one-click contract therefore has two lifecycle paths:

```text
Current-instance path: discover -> resolve compatible profile -> install -> validate
Upgrade path:          snapshot -> customer/platform upgrade -> observe -> revalidate
```

The current-instance path is the default. Gatekeeper does not equate “latest”
with “supported,” and it never approves an InstallPlan, changes an OLM
Subscription, upgrades OpenShift AI, or performs rollback on the customer’s
behalf.

## Ownership

| Concern | Owner | Gatekeeper behavior |
|---|---|---|
| OpenShift version and update | Platform administrator / OpenShift lifecycle | Discover and record; do not mutate |
| OpenShift AI operator and DataScienceCluster | OpenShift AI/OLM | Discover channel, approval mode, CSV, and readiness |
| MCP Gateway, RHCL, Authorino, Limitador, Service Mesh | Platform owner and their operators | Record exact installed state and evaluate the selected profile |
| Project Matrix layer resources | Project Matrix | Reconcile only declared namespaced resources and validate after transitions |
| Upgrade approval and rollback | Customer/platform owner | Gatekeeper supplies evidence and a promotion gate |

## No-upgrade path

When the customer cannot schedule an upgrade, Gatekeeper must:

1. discover the installed OpenShift and OpenShift AI versions;
2. discover the active OLM channels and approval modes;
3. resolve the Gateway profile against the installed support evidence;
4. refuse only unsupported or unsafe combinations, not merely older versions;
5. install the smallest compatible layer profile;
6. label any Technology Preview, Developer Preview, partner, community, or
   workaround dependency in the UI and evidence;
7. record the exact baseline so a later upgrade can be revalidated.

If the current baseline is compatible, it is a valid target even when a newer
InstallPlan is available for manual approval. Gatekeeper never turns a pending
upgrade into an implicit prerequisite.

## Upgrade path

Run the following before a platform-owned upgrade:

```bash
./gatekeeper.sh --profile production upgrade-preflight
```

This is read-only. It records OpenShift, OpenShift AI, OLM, layer-operator,
CRD/API, Gateway, and profile information at:

```text
.gatekeeper-runs/upgrade-baseline.json
```

The platform owner then performs the documented OpenShift/OpenShift AI upgrade
using the selected update channel and approval policy. After the platform
reports stable, run:

```bash
GATEKEEPER_UPGRADE_BASELINE=/path/to/upgrade-baseline.json \
  ./gatekeeper.sh --profile production upgrade-postcheck
```

The post-check compares operator and CRD transitions, detects active OLM
transitions, confirms DataScienceCluster and ClusterOperator stability, and
reruns the Gatekeeper preflight and Gateway validation. A failed post-check
means “revalidation required,” not “automatically roll back.”

## Upgrade safety rules

- Do not assume CRD versions, Gateway API behavior, listener semantics, or
  AuthPolicy behavior remain unchanged across OpenShift AI releases.
- Do not rely on a healthy CSV alone; validate the actual Gateway path,
  identity response, DNS/TLS edge, backend isolation, and MCP registrations.
- Treat OLM `RequiresApproval` plans as customer-controlled availability. They
  are reported as warnings; Gatekeeper does not approve them.
- Treat active `Installing` or `Pending` plans, failed non-copy CSVs, an
  unavailable/degraded/progressing ClusterOperator, or a non-Ready
  DataScienceCluster as a transition gate.
- Preserve customer-owned resources and re-discover names rather than assuming
  operator-generated names or resource versions survive an upgrade.
- Keep the Production/Preview toggle independent from upgrade execution. A
  Preview toggle may select a preview capability, but it must not approve or
  trigger an operator upgrade.
- Preserve evidence before and after every upgrade so a customer without a
  maintenance window can remain on a known, explicitly classified baseline.

## Current target-cluster implication

The live target currently has a manual-approval OpenShift AI InstallPlan for
the next operator version. That is not an authorization for Gatekeeper to approve
it and is not, by itself, a blocker to using the currently Ready
DataScienceCluster. The Gateway production claim remains independently gated
by the MCP Gateway Technology Preview support boundary and the native OIDC
AuthPolicy 500/401 compatibility defect already recorded in the Gatekeeper
evidence.
