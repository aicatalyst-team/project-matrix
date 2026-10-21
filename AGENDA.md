# Project Matrix agenda

Project Matrix is the internal codename for this Red Hat AI: Agentic Strategy
horizontal one-click program. The official layer names remain primary; the
Matrix secondary vocabulary is defined in
[`PROJECT_MATRIX_CONVENTION.md`](PROJECT_MATRIX_CONVENTION.md). The Dashboard
experience is **The Construct**, with Production as **The Red Path** and
Innovation as **The Blue Path**.

This is the working agenda for the horizontal one-click program. The canonical
architecture remains the Red Hat AI: Agentic Strategy stack:

```text
Infrastructure -> vLLM (Core) -> llm-d -> OGX -> Gateway
-> Secure Agent Onboarding -> AgentOps -> BYOA
```

## Execution priority — 2026-10-20

To avoid making functional testing wait on external release dependencies, the
current priority is the **Production-path completion track** on the live
OpenShift AI instance. This means completing and exercising the full
Red-Hat-managed control-plane experience with the currently available native
TokenReview evaluation profile, Dashboard host integration, teardown/reinstall,
status, evidence, and upgrade-safe behavior.

This track may be called **production-shaped** until a supported MCP Gateway
release or an approved time-bounded exception exists. Project Matrix must not
claim Red Hat Production support while the installed Gateway remains
Technology Preview.

The Innovation lane remains part of the same shipped artifact and is not being
removed or split out. Its live activation is deferred until the approved RHCL
1.5+ prerequisite is available. The pinned upstream release and fail-closed
installer are already implemented, so this sequencing decision does not change
the artifact contract or require a second implementation.

Quay promotion and RHCL 1.5+ availability are release/activation gates, not
prerequisites for continuing functional validation against the live cluster's
immutable evaluation images.

## Current checkpoint — 2026-10-21

| Workstream | State | Next result |
|---|---|---|
| Production/preview same-instance model | Implemented across UI, BFF, controller, Job, and standalone Gatekeeper defaults | `Production/Preview` operating-mode contract |
| Gatekeeper Gateway layer | Current-cluster routing/authentication proof is validated; the Red Hat support boundary, RHCL-documented OIDC path, and portable Aramco hardening gaps remain explicitly separated | Compare Red Hat packaging with upstream, qualify OIDC/`mcps` authorization, then close portable exposure/operator-scope gaps |
| Cross-layer control plane | Live evaluation path validated | Promote canonical release images and complete Dashboard host registration |
| Technology baseline | Defined | Go/controller-runtime, OLM, Argo CD/Kustomize, Jobs, PatternFly UI |
| Platform identity | Defined | OpenShift AI-native; Red Hat first, open-source/downstream compatible, no IBM runtime dependency |
| OpenShift AI UI | Federated package, BFF contract, status polling, live BFF/controller path, first-party host card, combined host, and isolated OAuth front door validated | Accept the host card through the normal operator-managed Dashboard release; direct image overrides are reconciled away |
| Other horizontal layers | Planned | Layer adapters using the same API |
| Use-case verticals | Deferred | Begin after layer contracts are stable |
| Aramock/customer workflow reuse | Inspected | Split fixtures, conformance workflows, and Bedrock-only mutations by layer |
| Repository boundary | Implemented | Project Matrix is isolated under `/Users/geraldtrotman/Virtualenvs/project-matrix`; Aramco assets used by Gatekeeper are vendored with provenance |
| Target OpenShift AI validation | Same production-grade cluster hosts the Red Hat baseline; teardown/reinstall and both one-click lanes were exercised live; Gateway UID was preserved | Keep the Red Hat OLM baseline intact; add the pinned upstream preview only after its RHCL 1.5+ prerequisite is available |
| Upgrade compatibility | Implemented as read-only baseline/post-check contract; no-upgrade path is explicit | Re-run post-check after any platform-owned OpenShift AI/operator upgrade |
| Image release | Controller, Gatekeeper, Dashboard BFF, and combined Dashboard host images are built and digest-verified on the live cluster; the corrected host digest is cluster-local | Promote the reviewed immutable set to canonical Quay after host dependency/security triage |
| Project Matrix migration | Matrix controller, Dashboard BFF, Gatekeeper executor, CRD, and isolated runtime are installed on the live cluster; the Production click correctly failed closed with evidence | Complete the combined host build, deploy the Matrix-named Dashboard evaluation copy, and exercise the UI click |
| Lean/secure quality bar | Persistent | Minimize components, privileges, runtime dependencies, and operator touchpoints without weakening resilience or evidence |

## Implementation checklist

- [x] Define and install the `LayerDeployment` API contract.
- [x] Establish and implement the Project Matrix naming convention across the
  Dashboard experience, Gateway intent (`Gatekeeper`), profile catalog, agenda,
  and journal with versioned technical identifiers for live-resource
  migration.
- [x] Implement static Production/Preview planning and support boundaries.
- [x] Make Production the safe default across UI, BFF, controller, Job, and standalone Gatekeeper entry points; Preview requires explicit selection.
- [x] Implement the Gatekeeper Job adapter, evidence handoff, and runner RBAC.
- [x] Implement same-instance intent conflict resolution.
- [x] Record Gateway/Aramock source provenance and profile contracts.
- [x] Add read-only Aramock-derived Gateway/MaaS conformance checks.
- [x] Repair the local Podman registry configuration and verify Red Hat image pulls.
- [x] Align release Containerfiles with Go 1.25 and non-root UBI builder output rules.
- [x] Align the Gatekeeper wrapper's default evidence path with its non-root Job filesystem contract.
- [x] Promote and pin the tested controller and Gatekeeper images in canonical Quay `aicatalyst`; the 2026-10-20 digests are recorded in the release lock.
- [x] Build and pin the renamed Project Matrix controller, Gatekeeper, and Dashboard images in the isolated live `project-matrix-build` lane; 2026-10-21 digests are recorded in the release lock.
- [x] Implement the OpenShift AI UI Production/Preview mode-switch scaffold.
- [x] Implement the constrained Project Matrix BFF route and reviewed namespace-scoped RBAC.
- [x] Support the OpenShift AI Dashboard proxy rewrite path in the BFF without widening its API surface.
- [x] Add a runnable federated frontend scaffold and local BFF proxy path.
- [x] Isolate Project Matrix from `mempalace-openshift` and relocate Gatekeeper evidence.
- [x] Remove the Gatekeeper image's old parent-repository build-context assumption.
- [x] Package the controller, BFF, CRD, Gatekeeper policy, and health probes as one Kustomize install boundary.
- [x] Add a read-only target-cluster baseline verification script.
- [x] Authenticate to and inventory the target OpenShift AI instance.
- [x] Run live innovation preflight, Gateway validation, and Aramock-derived conformance.
- [x] Apply the lean/optimized/robust/secure delivery review to Gatekeeper; live Gateway support/protocol gates remain separate acceptance blockers.
- [x] Verify the ingress GatewayAPIInstallConflict is non-blocking for Gatekeeper when Mesh 3 and the target Gateway API resources are healthy; retain the condition as platform-owner evidence.
- [x] Revalidate Gatekeeper after Mesh migration: ingress green, Mesh 3 healthy, Gateway API programmed.
- [x] Validate the cluster Keycloak OIDC discovery endpoint for the Gatekeeper issuer candidate.
- [x] Reduce production preflight to the explicit MCP Gateway Preview dependency after supplying the issuer candidate.
- [x] Add a production preflight gate for effective backend isolation, not merely the presence of a NetworkPolicy object.
- [x] Resolve the public MCP Gateway hostname/DNS-to-load-balancer mismatch causing HTTP 503; reconcile the exact record through the OpenShift DNS operator.
- [x] Resolve the MCP Lifecycle Operator’s permissive backend NetworkPolicy behavior through the reviewed OpenShift AdminNetworkPolicy isolation control; additive policies alone do not close the bypass.
- [ ] Complete the RHCL-documented OIDC mode with an approved short-lived credential and qualify the separate `mcps` listener authorization path; retain TokenReview as the OpenShift-native evaluation mode.
- [x] Provide an HTTPS listener/edge for the MCP Gateway using a scoped ReferenceGrant to the OpenShift wildcard certificate.
- [x] Make the installed Gateway's OpenShift TokenReview AuthPolicy enforcement return the standard 401 challenge; the earlier native OIDC 500 remains separately recorded as an OIDC compatibility gate.
- [x] Formally qualify the MCP Gateway Tech Preview dependency and native OIDC compatibility boundary using installed-version evidence and official Red Hat/Kuadrant documentation; the post-TLS OIDC unauthenticated 401 now passes, while positive identity and `mcps` authorization remain explicit.
- [x] Make the Production protocol validator fail closed on every non-401 unauthenticated MCP response, including AuthPolicy/data-plane HTTP 500 compatibility failures.
- [x] Inspect the live OLM package manifest; the target exposes only `mcp-gateway/preview`, with no supported channel available to select.
- [x] Add an explicit, version/channel-matched, expiring Production support-exception gate; Preview remains distinct from an exception.
- [x] Add the internal `mcps` listener requirement for authenticated `tools/call` authorization and verify it shares the public listener port.
- [x] Server-side dry-run the rendered AuthPolicy against the live API; schema/admission compatibility passes without applying the policy.
- [ ] Obtain an actual supported Gateway channel/release or an approved exception artifact; Project Matrix must not invent either.
- [x] Add/qualify the `mcps` listener and a runtime-compatible OpenShift TokenReview AuthPolicy path; verify both listeners share the public port.
- [x] Run authenticated `initialize`, `tools/list`, and an approved non-destructive `tools/call` with a short-lived service-account credential.
- [x] Make the validator carry the MCP session ID and normalize MCP SSE responses; production-profile protocol validation now passes.
- [x] Make OpenShift TokenReview the explicit Red Hat-native evaluation auth mode and mechanism-check it; do not equate it with the RHCL-documented OIDC production path.
- [x] Pin upstream MCP Gateway `v1.0.2` as the sole preview source, record its commit and RHCL 1.5+ prerequisite, and add a fail-closed isolated same-cluster installer.
- [x] Generalize the Aramco contract into Gatekeeper checks for exposure mode, ClusterIP/infrastructure parameters, operator scope/CSV copies, customer TLS Secret discovery, and credential omission.
- [x] Add an explicit `mcps` listener TokenReview AuthPolicy manifest for the OpenShift-native proof lane; positive OIDC/per-tool authorization validation remains a live gate.
- [x] Implement the read-only RHCL 1.5+ readiness gate and fail-closed upstream installer handoff; distinguish catalog absence from operator health and invalid scope.
- [x] Remove the invalid duplicate RHCL Subscription and stale failed CSV remnants from `mcp-gateway-system`; preserve the healthy global RHCL installation.
- [ ] Install and validate the pinned upstream preview on the same cluster after the platform owner makes RHCL 1.5+ available; the current RHCL 1.4.3 state is intentionally refused.
- [x] Enable the Red Hat OpenShift AI Authorino TLS bootstrap annotation and keep the custom Gateway unmanaged by MaaS AuthPolicy reconciliation.
- [x] Add current-instance-first upgrade compatibility contract; do not require customers to upgrade before Gatekeeper can evaluate a compatible baseline.
- [x] Add read-only `upgrade-preflight` and `upgrade-postcheck` evidence commands; never approve InstallPlans, mutate Subscriptions, or perform rollback.
- [x] Capture OpenShift AI channel/approval mode, CSVs, InstallPlans, CRD served/storage versions, and post-upgrade Gateway conformance requirements.
- [x] Package the Dashboard BFF deployment, authorized proxy rewrite, and feature-registration metadata as one Project Matrix boundary.
- [x] Build and validate the standalone module-federated remote, its manifest, and the Dashboard host-integration contract.
- [x] Analyze the standalone UI/BFF/controller path and verify the remote build and host contract.
- [x] Wire the Preview adapter to the isolated upstream installer contract and add asynchronous status polling; the live RHCL 1.5+ gate remains intentionally fail-closed.
- [x] Register the package in the compatible OpenShift AI Dashboard workspace and publish the combined Dashboard image.
- [x] Promote and pin the immutable dashboard BFF image digest for the current control-plane release; the combined host image remains separate.
- [x] Deploy the combined Dashboard host as an isolated live evaluation copy without modifying the operator-managed production Dashboard.
- [x] Add the dedicated Red Hat `kube-auth-proxy` OAuth front door, OAuthClient, re-encrypted Route, and constrained upstream NetworkPolicy for browser evaluation.
- [x] Persist the explicit external OpenShift OAuth authorization URL in the evaluation installer; validate the browser redirect and token-authenticated health path after the wildcard certificate repair.
- [x] Route evaluation OAuth code redemption through the in-cluster OpenShift OAuth Service with the service CA and persist the explicit external authorization URL; the repaired wildcard certificate now validates the browser path.
- [x] Validate the complete Gatekeeper production and innovation control-plane paths on the target instance; the infrastructure-dependent gates fail closed with explicit evidence.
- [x] Install the renamed Matrix control plane into `matrix-system` without changing the Red Hat-managed Gateway, then exercise the BFF one-click path for Gateway / The Gatekeeper / Production.
- [x] Deploy and validate the renamed combined Dashboard host and its OAuth front door on the live Matrix runtime; the browser route now returns the expected external OpenShift OAuth redirect.
- [ ] Accept the Project Matrix homepage tile into the normal OpenShift AI Dashboard host release; direct image overrides were tested and reconciled away by the operator.
- [x] Add explicit teardown/reinstall handling for the optional combined-host and OAuth evaluation resources without targeting the operator-managed Dashboard.
- [x] Establish the lean release contract: customer installs pull immutable runtime images and apply manifests; maintainer builds exclude local dependency caches and unrelated source trees.
- [ ] Triage the combined Dashboard host dependency audit findings before calling the host release production-grade.
- [ ] Add the next horizontal layer adapter after Gatekeeper contracts are accepted.

## Current next actions

1. Complete the remaining production-shaped Dashboard release review: triage
   the combined host dependency audit and decide whether the evaluated host
   becomes the supported OpenShift AI Dashboard build input. The isolated host,
   its dedicated OAuth front door, and the repeatable opt-in teardown/reinstall
   path are now live and validated for the prior evaluation host; the renamed
   Matrix host build is being rebuilt with the bounded release context.
2. Verify the optimized image release path: record the new combined-host
   digest, deploy it only to the isolated evaluation copy, and confirm that
   the customer instructions contain no build, source-upload, or local-runtime
   step. See [`deploy/RELEASE_PERFORMANCE.md`](deploy/RELEASE_PERFORMANCE.md).
3. Treat the current OpenShift AI baseline as independently usable when it
   satisfies the compatibility contract; do not approve the pending manual
   InstallPlan from Gatekeeper. Use `upgrade-postcheck` only after a
   platform-owned upgrade.
3. Keep Mesh 2 removal out of Project Matrix’s critical path; the migration is
   complete and the ingress operator is now green.
4. Use the release contract: the live Red Hat package is `mcp-gateway.v0.7.1`
   on `preview`, while the sole preview lane is pinned upstream `v1.0.2`
   (`e48ae51c`). The invalid duplicate namespace-scoped RHCL installation has
   been removed and the global RHCL installation remains healthy. The only
   remaining platform-owner action is to publish an approved RHCL 1.5+ OLM/
   catalog path. Then run the isolated preview installer; do not substitute an
   upstream image into the live OLM path.
5. Qualify the RHCL-documented OIDC path and the explicit `mcps` authorization
   policy. The OpenShift TokenReview path is proven for evaluation, but it is
   not by itself evidence of the documented RHCL customer-identity path.
6. Promote the tested evaluation images to canonical Quay or an approved
   immutable mirror without changing the one-package/two-lane contract.
7. Obtain RHCL 1.5+ for the isolated upstream Innovation lane and qualify the
   actual upstream install; Production remains fail-closed until a supported
   Gateway channel or approved exception exists.
8. Begin the next horizontal adapter only after the Gateway click is proven
   and the host-integrated release is accepted.

## Lean platform quality gate

Every layer must earn acceptance against the following constraints:

- **Lean:** prefer existing OpenShift AI capabilities and one controller path;
  avoid duplicate gateways, APIs, operators, or bespoke control planes.
- **Optimized:** use bounded resources, idempotent reconciliation, cached or
  reused platform services, and the smallest supported image/runtime surface.
- **Robust:** fail before mutation, preserve Production and Preview
  coexistence, expose health/status/evidence, and support retry, rollback, and
  disconnected operation where the platform contract requires it.
- **Secure:** least privilege, non-root containers, pinned artifacts, trusted
  proxy identity, secret-free evidence, explicit network boundaries, and no
  customer-specific mutation hidden in a horizontal layer.

The gate is reviewed at design, build, install, and live-validation time. A
layer is not accepted merely because its happy path works on one cluster.

## Definition of the one-click contract

The user chooses only:

```text
Preview capabilities: OFF | ON
```

The control plane handles layer dependencies, supported/preview versions,
namespaces, routes, identity, policies, evidence, rollback, and diagnostics.
It must stop before mutation when dependencies cannot coexist safely.

## Execution order

1. Define and install the `LayerDeployment` API.
2. Complete the Gatekeeper adapter and status conditions.
3. Add same-instance dependency resolution and conflict reporting. **Implemented for competing `LayerDeployment` owners; live cluster/operator discovery remains.**
4. Deliver the OpenShift AI UI mode switch. **Package, BFF contract, host metadata, standalone remote, status polling, live BFF/controller path, isolated combined Dashboard host, and dedicated OAuth front door are validated. The operator-managed production Dashboard remains untouched; host dependency security triage remains an explicit gate.**
5. Validate production and preview behavior on the Gatekeeper instance.
   **Live control-plane execution completed 2026-10-19:** control-plane teardown/reinstall,
   authenticated BFF access, Production fail-closed execution, and the same
   resource switching to isolated Innovation/Preview all pass. Infrastructure
   release gates remain explicit: supported Gateway/RHCL 1.5+ availability.
6. Add adapters for the remaining horizontal layers.
7. Define specific use-case verticals against the completed layer contracts.

## Gateway correctness contract from Aramco validation

The Saudi Aramco reference layout is now a required Gatekeeper acceptance
contract. The one-click layer must remove these operational assumptions from
the customer path:

- **Listener topology:** public MCP and `*.mcp.local` routing use the same
  listener port; the router authority rewrite, Envoy same-listener routing,
  and per-port EnvoyFilter attachment are validated together.
- **Named resources:** `MCPGatewayExtension.spec.targetRef.sectionName` must
  resolve to an actual Gateway listener; missing or invented listener names
  fail before mutation.
- **Private service discovery:** `privateHost` is derived from the actual
  Gateway Service and GatewayClass, never from a hard-coded
  `<gateway>-istio` assumption. Discovery and `tools/call` are tested, not
  inferred from `tools/list`.
- **CRD compatibility:** generated HTTPRoute fields are limited to the
  served schema; unsupported `spec.rules[].name` fields are rejected and
  reconciliation churn is surfaced.
- **Exposure:** LoadBalancer, ClusterIP plus infrastructure parameters, and
  OpenShift Route exposure are explicit profile choices with status evidence.
- **TLS:** the selected Secret is discovered/configured explicitly; the
  `default-ingress-cert` name is never assumed.
- **Operator scope:** dedicated-namespace and `openshift-operators`
  all-namespaces installations report the controller namespace, CSV copies,
  and the namespace in which extension resources must live.
- **Credentials:** unauthenticated backends omit `credentialRef`; credential
  references are created only when the selected backend requires them.
- **Protocol proof:** validation covers registration readiness, authenticated
  `initialize`, `tools/list`, and an explicitly approved `tools/call`, while
  never placing tokens or tool output in evidence.

**Implemented 2026-10-19:** Gatekeeper now validates MCPGatewayExtension
readiness, resolves `sectionName` against a live Gateway listener, derives the
Service name from the `privateHost` FQDN, verifies the Service port and the
same-port public/private contract, and rejects unsupported HTTPRoute rule
fields. Live validation passed all of these checks on the target instance.
The checks are now generalized into the installer contract. Live qualification
of the portable ClusterIP/infrastructure-parameters profile, the upstream
preview release, customer OIDC, and `mcps` authorization remains outstanding.

These are implementation gates for the Gateway horizontal, not customer
documentation tasks. The one-click contract is successful only when the
selected profile renders a working reference layout and explains the exact
resource or platform condition when it cannot.
