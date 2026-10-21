# RHCL readiness gate

`check-readiness.sh` is a read-only platform prerequisite check for the sole
upstream MCP Gateway preview. It verifies:

- RHCL 1.5.0 or newer is present in the approved OpenShift OLM catalog;
- the cluster-wide RHCL installation is `Succeeded` under the global
  `openshift-operators` OperatorGroup; and
- no duplicate namespace-scoped RHCL subscription is attempting to install an
  AllNamespaces-only operator.

Run it with an authenticated `oc` session:

```bash
RHCL_MIN_VERSION=1.5.0 bash gatekeeper/rhcl/check-readiness.sh
```

The command is intentionally non-remediating. Platform owners must make the
approved RHCL catalog/channel available and perform any OLM cleanup or upgrade.
Project Matrix must not delete subscriptions, approve InstallPlans, or mutate
OperatorGroups as part of a Gateway one-click deployment.
