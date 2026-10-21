# Project Matrix: Gatekeeper

Project Matrix: Gatekeeper is the first horizontal one-click deployment for the
Red Hat AI: Agentic Strategy **Gateway** layer. It assumes OpenShift AI is
already installed and turns the existing MCP Gateway/MaaS foundation into a
tracked evaluation experience:

```text
Preflight -> Install -> Validate -> Evaluate -> Diagnostics
```

The installer has two explicit lanes:

| Lane | Purpose | Claim |
|---|---|---|
| `innovation` | Run the single pinned upstream MCP Gateway preview on the same OpenShift AI cluster, with real Red Hat platform constraints | Upstream innovation evidence only; isolated and not Red Hat-supported |
| `production` | Validate a supported configuration and fail closed on degraded platform state or preview dependencies | Production candidate only after all gates pass |

The profile contract is maintained in
`gatekeeper/profiles/catalog.json`. It records source provenance,
canonical Red Hat AI: Agentic Strategy layer mapping, required and optional
capabilities, evidence expectations, and mutations that are explicitly out of
scope for the Gateway click. Validate it locally with:

```bash
./gatekeeper/profiles/validate-catalog.sh
```

The sole preview release is recorded in
[`releases/mcp-gateway.json`](releases/mcp-gateway.json): upstream MCP Gateway
`v1.0.2` at commit `e48ae51c`. The Red Hat OLM package remains the
production/support baseline. To install the upstream preview into an isolated
namespace on the same cluster, first verify the platform prerequisite and then
explicitly confirm the mutation:

```bash
GATEKEEPER_CONFIRM_UPSTREAM_PREVIEW=1 \
  bash gatekeeper/preview/install-upstream.sh
```

The installer requires RHCL 1.5.0 or newer, uses a separate Gateway/Route, and
refuses to create anything when that prerequisite is absent. It never upgrades,
replaces, or relabels the Red Hat OLM-managed Gateway.

The RHCL prerequisite can be inspected independently:

```bash
RHCL_MIN_VERSION=1.5.0 bash gatekeeper/rhcl/check-readiness.sh
```

This is a read-only platform gate. It confirms catalog availability, the
cluster-wide AllNamespaces installation, and absence of a duplicate
namespace-scoped RHCL subscription. It does not approve InstallPlans, change
Subscriptions, or repair OperatorGroups.

## First run

```bash
cd /Users/geraldtrotman/Virtualenvs/project-matrix/gatekeeper
chmod +x gatekeeper.sh

# Saudi Aramco innovation-lane rehearsal; does not uninstall or replace operators.
./gatekeeper.sh --profile innovation all
```

The cluster must already be authenticated with `oc`. Evidence is written to
`.gatekeeper-runs/` and contains no bearer tokens or Kubernetes Secret values.

## Live endpoint validation

Set the secured MCP endpoint for the target cluster. The URL is deliberately
not embedded in the installer:

```bash
GATEKEEPER_MCP_URL=https://<secured-mcp-host>/mcp \
  ./gatekeeper.sh --profile innovation validate
```

For a positive protocol test, pass a short-lived token in the environment. It
is used in memory only and is never written to the report:

```bash
GATEKEEPER_MCP_URL=https://<secured-mcp-host>/mcp \
GATEKEEPER_BEARER_TOKEN="$TOKEN" \
  ./gatekeeper.sh --profile innovation validate
```

With a short-lived token, validation proves the complete non-destructive MCP
surface: registration readiness, `initialize`, and `tools/list`. To add an
approved `tools/call`, provide the exact tool and JSON arguments supplied by
the customer workflow:

```bash
GATEKEEPER_MCP_URL=https://<secured-mcp-host>/mcp \
GATEKEEPER_BEARER_TOKEN="$TOKEN" \
GATEKEEPER_MCP_TOOL_NAME='<approved-read-only-tool>' \
GATEKEEPER_MCP_TOOL_ARGUMENTS_JSON='{"query":"gatekeeper verification"}' \
  ./gatekeeper.sh --profile innovation validate
```

Tool names and arguments are deliberately opt-in. Gatekeeper never guesses a
tool call, records bearer tokens, or writes MCP response bodies to evidence.
This keeps the protocol proof useful for Aramco-style workflows without
turning validation into an unreviewed customer operation.

The Red Hat-native default authentication mode is OpenShift Kubernetes
TokenReview (`GATEKEEPER_AUTH_MODE=tokenreview`). Native OIDC is an explicit
alternate mode for customer identity providers:

```bash
GATEKEEPER_AUTH_MODE=oidc \
GATEKEEPER_OIDC_ISSUER=https://<supported-issuer>/realms/mcp \
  ./gatekeeper.sh --profile production preflight
```

To run the inspectable MCP-to-MaaS reference evaluation:

```bash
GATEKEEPER_MCP_URL=https://<secured-mcp-host>/mcp \
GATEKEEPER_OIDC_ISSUER=https://<keycloak-host>/realms/mcp \
GATEKEEPER_MAAS_URL=https://<maas-host> \
GATEKEEPER_ROUNDTRIP=1 \
  ./gatekeeper.sh --profile innovation evaluate
```

The production profile is the default when no profile is supplied. The
innovation profile must be selected explicitly and represents the Preview
toggle from the OpenShift AI Dashboard.

## Upgrade-aware operation

Gatekeeper supports customers that cannot schedule an OpenShift AI upgrade. The
current-instance path discovers the installed release and selects a compatible
profile; it does not require the newest InstallPlan. A pending manual-approval
upgrade is reported but is never approved by Gatekeeper.

When a platform-owned upgrade is planned, capture a read-only baseline first:

```bash
./gatekeeper.sh --profile production upgrade-preflight
```

After the platform team completes and stabilizes the upgrade, revalidate the
same layer:

```bash
GATEKEEPER_UPGRADE_BASELINE=/path/to/upgrade-baseline.json \
  ./gatekeeper.sh --profile production upgrade-postcheck
```

The post-check compares operator and CRD/API transitions and reruns the
Gateway preflight and validation. It never approves an InstallPlan, changes an
OLM Subscription, upgrades OpenShift AI, or performs rollback. See
[`UPGRADE_COMPATIBILITY.md`](UPGRADE_COMPATIBILITY.md) for the lifecycle
contract and ownership boundaries.

The innovation profile also runs a read-only Aramock-derived conformance check
for the MaaS Gateway, simulator, MaaSModelRef, MaaSAuthPolicy,
MaaSSubscription, and optional endpoint. It does not run Aramock bootstrap,
provision GPUs, modify cluster-wide policy, or create credentials. Configure
the fixture names with `GATEKEEPER_ARAMOCK_*` variables when the customer
environment differs from the reference fixture.

The round-trip reuses the manual Saudi Aramco scripts, so the customer can
inspect and run the troubleshooting path independently of the one-click flow.

## What the installer changes

The first implementation is intentionally narrow and inspectable:

- creates the `matrix-system` deployment record with layer, code name, lane,
  profile, and phase metadata;
- applies the existing Gateway-only backend `NetworkPolicy` when enabled and
  proves its *effective* behavior with a temporary bypass probe;
- optionally applies the native OIDC `AuthPolicy` after the issuer is supplied;
- reconciles the exact Gateway hostname through the OpenShift DNS operator when
  the selected profile enables `GATEKEEPER_MANAGE_GATEWAY_DNS`;
- optionally installs the read-only OpenShift MCP fixture;
- validates Gateway API, MCP registrations, OpenShift AI readiness, identity,
  protocol behavior, and backend bypass;
- captures cluster diagnostics for the exact run.

It does not silently install or uninstall Service Mesh, RHCL, Authorino,
Limitador, or other cluster-wide operators. A formal ingress
`GatewayAPIInstallConflict` is treated as non-blocking only when the selected
Mesh 3 control plane, GatewayClass, and Gatekeeper Gateway are all healthy;
otherwise it remains a production blocker. The condition is always recorded
in the evidence bundle for platform-owner follow-up.

Gatekeeper also reports operator scope across the configured namespaces, checks
the actual Gateway Service and Route exposure, discovers customer TLS Secrets
for native HTTPS listeners, verifies that unauthenticated backend registrations
omit `credentialRef`, and requires a distinct `mcps` listener AuthPolicy when
the selected profile enables that gate. These are generalized from the Saudi
Aramco MCP Gateway findings rather than being customer-specific exceptions.

The Aramock customer-workflow suite is used as a classified source for
MaaS/OIDC fixtures, optional evaluation backends, observability checks, and
Aramco acceptance workflows. Its full bootstrap is not invoked by Gatekeeper:
GPU provisioning, cluster-wide proxy/image policy, DNS cutover, and destructive
MaaS Gateway reset remain explicit Infrastructure/Bedrock operations.

The MCP Lifecycle Operator may also create a permissive NetworkPolicy for an
`MCPServer`. Kubernetes NetworkPolicies are additive, and the installed
MCPServer CRD exposes no supported field to change that generated policy. In
that case the Gatekeeper bypass probe remains a required gate and will fail until
the backend is moved to a policy-controllable deployment profile, the operator
gains a supported isolation control, or a separately reviewed OpenShift
AdminNetworkPolicy is installed by a platform administrator. Gatekeeper does not
silently create that cluster-scoped policy because both lanes currently forbid
cluster-wide mutations.

The reviewed prerequisite is shipped at
`gatekeeper/manifests/mempalace-adminnetworkpolicy-prerequisite.yaml`. After
platform-owner approval, apply that exact manifest and rerun the Gatekeeper
validation; the production preflight and direct-bypass probe are the acceptance
checks. Do not substitute a broad cluster-wide deny policy or change the
subject/peer selectors without re-reviewing the Gateway route.

## Production gate

```bash
./gatekeeper.sh --profile production preflight
```

This will fail closed on a material OpenShift `ingress` degradation, a known
preview Gateway dependency, a missing/non-enforced AuthPolicy matching the
selected authentication mode, or an HTTPS edge that is not ready. The default
mode is OpenShift TokenReview; native OIDC is opt-in and requires an approved
issuer. The specific
`GatewayAPIInstallConflict` compatibility condition may be reported as a
warning when the required Gateway API resources are healthy; this preserves
the distinction between operator health and actual Gatekeeper path readiness.

The installed target cluster currently exposes MCP Gateway through its
`preview` catalog channel. That is the remaining explicit Production-lane blocker until
the channel is qualified for the intended support posture or a supported
channel is available. An AuthPolicy that is merely Accepted/Enforced is not
enough: the selected auth mode must match the policy and the edge must return a
standard 401 challenge for an unauthenticated request. If the installed
Gateway release produces an upstream 500 instead, the Production validator
fails closed even when the AuthPolicy status itself is Accepted/Enforced.

If the platform owner has an explicit, time-bounded exception for operating
the Preview dependency, provide a matching exception file:

```bash
GATEKEEPER_SUPPORT_EXCEPTION_FILE=/secure/path/mcp-gateway-exception.json \
  ./gatekeeper.sh --profile production preflight
```

The exception must match the installed OLM version and channel and does not
turn the Preview feature into Red Hat-supported software. Its purpose is to
make the governance decision explicit while preserving the remaining
production gates. See `gatekeeper/exceptions/README.md` for the required shape.

## Controller executor image

The controller can run this same inspectable workflow as a Kubernetes Job when
`GATEKEEPER_EXECUTOR_IMAGE` is explicitly configured. The checked-in
`Containerfile` is the build contract; mirror the resulting image into the
customer-approved registry and pin the image version before enabling it.

The executor expects the `project-matrix-gatekeeper-runner` service account and a
reviewed RBAC policy. The controller does not silently grant cluster-wide
permissions or embed customer credentials.

Install the reviewed runner policy as a platform-administrator prerequisite:

```bash
oc apply -f /Users/geraldtrotman/Virtualenvs/project-matrix/gatekeeper/manifests/gatekeeper-runner-rbac.yaml
```

The policy separates read-only cluster observation from narrowly scoped writes
for Gatekeeper evidence, backend NetworkPolicies, the Gateway AuthPolicy, and
the temporary direct-bypass probe. Optional evaluation fixtures require their
own separately reviewed permissions.

## Canonical vocabulary

Gatekeeper is an internal code name. Customer-facing output uses the Red Hat
strategy terms **Gateway**, **MCP Gateway**, **MaaS Gateway**, **Secure Agent
Onboarding**, and **AgentOps**. Gatekeeper consumes contracts from the other
layers; it does not redefine them.
