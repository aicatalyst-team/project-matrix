# Project Matrix: Gateway / The Gatekeeper

## Red Hat AI Agentic Strategy Gateway Layer Evaluation Kit

**Status:** Draft v0.2  
**Date:** 2026-10-14  
**Audience:** Red Hat platform engineers, solution architects, customer evaluators, and the Saudi Aramco delivery team

## 1. Purpose

Project Matrix: Gateway / The Gatekeeper is the first horizontal one-click
deployment in Project Matrix. It packages the **Gateway** layer of the Red Hat
AI: Agentic Strategy into a simple, inspectable, and immediately evaluable
customer experience.

The Matrix naming convention is secondary to the official Red Hat terminology;
see `PROJECT_MATRIX_CONVENTION.md` for the complete mapping and lane language.

The target customer already has OpenShift AI installed. The customer should not need to assemble MCP Gateway, MaaS Gateway, identity, routing, policies, test servers, or telemetry by following a long sequence of independent documentation pages.

The product goal is:

> One click from an OpenShift AI baseline to a working, authenticated MCP-to-MaaS evaluation with visible evidence, official documentation mapping, and downloadable troubleshooting tools.

This is not an attempt to hide the platform. It is an opinionated implementation of the documented platform path.

## 2. Project Matrix placement

```text
Infrastructure
  -> vLLM (Core)
  -> llm-d
  -> OGX
  -> [Gateway: Project Matrix: The Gatekeeper]
  -> Secure Agent Onboarding
  -> BYOA
  -> AgentOps
```

Gatekeeper lives in the **Gateway** layer and connects:

- MaaS access to model endpoints;
- MCP clients to federated MCP servers;
- identity and authorization to request routing;
- quotas and rate limits to governed consumption;
- AgentOps evidence to every request path.

Gatekeeper may consume capabilities from other layers, but it must not silently redefine them. The layer contract is the boundary.

## 3. Customer outcome

After deployment, the customer can:

1. Authenticate to the gateway.
2. Discover federated MCP tools.
3. Call a real MCP tool through the gateway.
4. Route an authenticated request to a MaaS-served model.
5. Run a tool-grounded model interaction.
6. Observe identity, gateway, tool, model, and telemetry hops.
7. Confirm that unauthorized and direct-bypass paths are denied.
8. Download the scripts and evidence used to validate the result.

The customer evaluates the Gateway layer itself, not a simulated UI or a collection of healthy Pods.

## 4. Canonical Red Hat AI terminology

The external documentation and UI must use the official strategy names:

- **Gateway** — the horizontal layer.
- **MCP Gateway** — governed MCP protocol entry and federation.
- **MaaS Gateway** — governed model access and model subscription path.
- **OGX** — the API, RAG, connector, and orchestration capability consumed by the agent path.
- **AgentOps** — traces, evaluation, guardrails, cost, and evidence consumed by the Gateway evaluation.

“The Gatekeeper” is an internal Project Matrix codename. It must never replace
the actual Red Hat component or product name. The technical migration is
versioned so the live cluster is never renamed implicitly by a UI click.

## 5. Support and evidence boundary

The installer must label every component in the generated deployment report.

| Capability | Initial classification | Rule for Gatekeeper |
|---|---|---|
| OpenShift AI baseline | Red Hat platform capability | Required precondition; version-gate every supported configuration. |
| Models-as-a-Service | Red Hat OpenShift AI capability | Use the supported MaaS configuration for the target release. |
| MCP Catalog / MCP Lifecycle Operator | Technology Preview where indicated by the target OpenShift AI release | Enable only through an explicit profile and show the support boundary. |
| MCP Gateway Operator / Red Hat Connectivity Link | External dependency; Technology Preview in the demonstrated RHCL path | Pin versions, verify prerequisites, and disclose support status. |
| Gateway API / Service Mesh | Red Hat/OpenShift capability with profile-specific requirements | Validate the exact GatewayClass, listener, route, and mesh configuration. |
| Authorino / Limitador | Gateway dependency | Report installation and enforcement status separately. |
| RHBK or customer OIDC provider | Customer identity integration | Never embed customer credentials; validate issuer reachability and claim policy. |
| OpenShift MCP server | Red Hat or catalog-provided evaluation fixture, depending on release | Identify the exact image and support tier. |
| MemPalace or another customer MCP server | Customer/demo fixture | Treat as an evaluation backend, not a native platform requirement. |
| MLflow / OpenTelemetry evidence | AgentOps integration | Telemetry failure must be visible and must not be misreported as a successful trace. |
| Edge Envoy JWT workaround | Demo or hardening artifact unless formally supported | Never present it as native Gateway enforcement. Label it explicitly. |

The installer must distinguish **Red Hat supported**, **Technology Preview**, **partner-supported**, **community-supported**, and **demo-only** behavior in both the UI and the generated report.

## 5.1 Production and innovation lanes

Gatekeeper is designed for two deliberate operating lanes. Both lanes use the same Gateway layer contract and evidence model, but they make different claims.

### Production lane

The production profile may include only the versions, configurations, and integrations covered by the target Red Hat support boundary. It must provide:

- repeatable installation and upgrade behavior;
- security, isolation, recovery, and operational evidence;
- documented failure and rollback behavior;
- no unmarked workaround or preview dependency;
- a report that states exactly what production claim is being made.

### Innovation lane

The innovation profile may include Technology Preview, Developer Preview, early-access, partner, community, or future capabilities when they are needed to demonstrate the direction of the platform. It must provide:

- explicit preview/support labels in the UI, manifests, and report;
- pinned component versions and image references;
- a reproducible demonstration path;
- known limitations, defects, and workaround disclosures;
- a documented promotion, migration, or replacement path toward production.

Innovation capabilities are first-class evaluation content, but they must never be presented as production-ready by implication. Every Gatekeeper artifact must carry at least: `lane`, `supportTier`, exact component versions, prerequisites, limitations, evaluation status, and promotability.

The customer experience should remain one click within either lane. The click selects a declared profile; it does not blur the boundary between a supported production deployment and a future-capability demonstration.

## 5.1.1 End-user operating-mode control

The end-user UI must expose one simple operating-mode switch, not individual
platform assembly controls:

```text
Preview capabilities:  OFF | ON
```

- **OFF** selects the production path: supported versions, configurations, and
  operational claims only.
- **ON** selects the innovation path: Technology Preview, Developer Preview,
  early-access, partner, community, or future capabilities that have been
  installed and validated on the same instance.

The controller resolves dependencies and changes the active implementation or
route according to the selected mode. It does not blindly install or remove
shared Operators when the switch changes. Users do not select Operators, CRDs,
namespaces, routes, Service Mesh versions, or credentials.

The UI must always display the active mode and support boundary. If a preview
component replaces a production component on the active request path, that
path is labeled preview while enabled. If the two implementations can run
side-by-side, the switch changes routing or activation without destroying the
inactive lane.

## 5.2 Same-instance coexistence

The target deployment is one OpenShift AI instance with both lanes available.
Gatekeeper must install supported production capabilities and preview/future
capabilities as explicitly isolated profiles whenever their dependency graph
permits coexistence.

The dependency resolver must account for:

- shared Operators and control planes;
- CRD and API-version ownership;
- GatewayClass, listener, hostname, and route collisions;
- namespace, service-account, RBAC, and NetworkPolicy boundaries;
- model, storage, telemetry, and identity dependencies;
- upgrade and rollback ownership.

If a production and preview component cannot coexist safely, the resolver must
stop before mutation and identify the conflict. A separate acceptance cluster
is an exception for an explicit incompatibility or for uncontaminated
production certification—not the default answer.

## 6. Layer contract

### 6.1 Required inputs

- Existing OpenShift AI cluster.
- Cluster administrator authorization for the installation workflow.
- Valid OpenShift AI and registry access.
- Configured or selected OIDC issuer.
- A reachable model endpoint or MaaS configuration.
- At least one MCP server registration or an evaluation MCP server fixture.
- Storage and telemetry prerequisites required by the selected profile.

### 6.2 Exposed capabilities

Gatekeeper must expose or make verifiable:

- authenticated MCP endpoint;
- MCP session initialization;
- federated `tools/list` behavior;
- tool-level request routing;
- MaaS model endpoint access;
- request authentication and authorization;
- route and namespace policy;
- quota and rate-limit policy where enabled;
- trace and audit correlation identifiers;
- clear endpoint and credential-reference outputs.

### 6.3 Downstream contracts

The following capabilities must be consumable by future layers and verticals:

```text
gateway.mcp.endpoint
gateway.mcp.tool-discovery
gateway.mcp.tool-call
gateway.maas.endpoint
gateway.auth.oidc
gateway.policy.authorization
gateway.policy.rate-limit
gateway.telemetry.correlation
```

Verticals must request these capabilities rather than depend directly on individual Deployments, Services, Pods, or implementation-specific names.

## 7. Dependency model

### 7.1 Hard dependencies

The initial resolver must validate, at minimum:

```text
OpenShift
  -> OpenShift AI
  -> required Gateway API / Service Mesh capabilities
  -> identity provider reachability
  -> model endpoint or MaaS capability
  -> MCP Gateway dependency
  -> MCP server registration
  -> validation/evaluation runner
```

The exact dependency graph is release-specific and must be discovered from the selected component versions rather than assumed by the UI.

### 7.2 Capability dependencies

Gatekeeper should consume capability contracts for:

- `identity.oidc`
- `inference.maas`
- `gatewayapi.route`
- `mcp.server-registration`
- `observability.trace`
- `policy.authorization`

This permits a later vertical to use the same Gateway contract even when the underlying implementation changes.

### 7.3 Optional integrations

The following may be enabled by profile:

- external OIDC providers;
- external model providers through the MaaS path;
- customer MCP servers;
- external telemetry backends;
- network-policy hardening;
- mesh mTLS hardening;
- token and cost metering;
- AgentOps evaluation suites.

Optional does not mean invisible. The deployment report must state whether each optional capability is enabled, disabled, unavailable, or not evaluated.

## 8. One-click lifecycle

The deployment must execute the following phases as one tracked run:

### Phase 1 — Preflight

Validate:

- OpenShift and OpenShift AI versions;
- cluster-admin access;
- required namespaces and CRDs;
- Operator availability and versions;
- Gateway API and Service Mesh readiness;
- OIDC issuer reachability and issuer claim expectations;
- model endpoint or MaaS readiness;
- MCP server image and registration inputs;
- route, DNS, certificate, and storage prerequisites.

### Phase 2 — Install

Install or configure only the components required by the selected Gatekeeper profile. Installation must be ordered by dependency and must record every applied resource.

### Phase 3 — Configure

Apply the opinionated reference configuration for:

- MCP Gateway;
- MaaS Gateway;
- listeners and routes;
- identity and authorization policy;
- MCP server registrations;
- model endpoint routing;
- network isolation;
- telemetry correlation;
- evaluation fixtures.

### Phase 4 — Validate

Run deterministic checks and expose their output in the UI and downloadable bundle.

### Phase 5 — Evaluate

Run the live MCP-to-MaaS reference task:

```text
Summarize the current MCP gateway architecture using live cluster and memory observations.
```

The evaluation must use real MCP discovery, real tool calls, a real MaaS model request, and recorded telemetry.

### Phase 6 — Report

Publish:

- overall status;
- layer status;
- component versions;
- endpoint references;
- validation results;
- evaluation result;
- telemetry links;
- troubleshooting bundle;
- official documentation map;
- support classification and known limitations.

The report must also include the selected lane, profile name, support tier of every dependency, exact versions/images, preview limitations, and whether the result is promotable to the production lane.

## 9. Validation and evaluation suite

### 9.1 Identity and access

- No token produces the expected unauthorized response.
- Invalid or expired token is rejected.
- Valid token reaches the intended gateway path.
- Issuer, audience, role, and claim behavior is recorded.
- The token is not forwarded to an unintended backend.

### 9.2 MCP protocol

- `initialize` succeeds for an authorized client.
- `tools/list` returns the expected federated catalog.
- A known tool call succeeds through the gateway.
- An unauthorized tool or route is denied.
- Backend direct access is blocked where the secure profile requires it.

### 9.3 MaaS and model path

- The model endpoint is reachable through the configured MaaS path.
- The request is associated with the expected subscription or policy.
- Token or quota behavior is visible when enabled.
- The response is correlated with the MCP request where the reference flow requires it.

### 9.4 Agentic round trip

- The agent receives the MCP tool catalog.
- The model selects or is given the expected tool path.
- The tool result is returned to the model.
- The final answer includes the grounded observations.
- The full path is visible in telemetry.

### 9.5 Resilience and hardening

- Gateway and dependency readiness are rechecked after a controlled restart.
- A failed dependency reports the correct phase and remediation.
- Network-policy or mesh hardening blocks backend bypass.
- Failure modes fail closed where the security profile requires it.
- The deployment report does not claim production readiness when a Technology Preview or workaround is involved.

## 10. Troubleshooting assets

The existing manual assets become first-class Gatekeeper artifacts:

- `aramco-mcp-lifecycle/MCP_LIFECYCLE_RUNBOOK.md` — explanatory installation path;
- `aramco-mcp-lifecycle/hardening/verify.sh` — security and persistence verification;
- `demos/mcp-gateway-lifecycle-demo.sh` — presenter and lifecycle flow;
- `aramco-mcp-lifecycle/maas-mcp-roundtrip/run.sh` — live MaaS/MCP round trip;
- `aramco-mcp-lifecycle/SAUDI_ARAMCO_E2E_STORY.md` — customer narrative and evidence path;
- `aramco-mcp-lifecycle/RH_TECH_PREVIEW_DEFECTS.md` — known issues and honest workarounds.

The one-click workflow may call these assets or their extracted checks, but the original inspectable scripts must remain available to the customer.

## 11. Required deliverables

Project Matrix: Gatekeeper will produce:

1. A declarative layer deployment resource.
2. An ordered installation workflow.
3. A preflight command and/or validation container.
4. Gateway configuration manifests.
5. MCP and MaaS evaluation fixtures.
6. Automated smoke and conformance tests.
7. A customer-facing evaluation UI or dashboard entry point.
8. A downloadable diagnostics bundle.
9. An official documentation cross-reference.
10. A support-boundary and known-limitations report.
11. A repeatable Saudi Aramco demonstration path.

## 12. Acceptance criteria

Gatekeeper is ready for customer evaluation when:

- a clean OpenShift AI baseline can be preflighted;
- one tracked action installs the selected Gateway profile;
- the installation can be inspected and reproduced from generated artifacts;
- authentication, MCP discovery, tool execution, and MaaS routing all work;
- the reference evaluation completes against live services;
- identity, gateway, model, tool, and telemetry evidence is correlated;
- direct backend bypass is tested and reported;
- troubleshooting scripts work independently of the UI;
- all known Technology Preview and workaround boundaries are visible;
- the selected production or innovation lane is visible before installation and in every generated artifact;
- innovation results do not imply a production support claim, and the report identifies a promotion path where one exists;
- the customer can follow the official Red Hat documentation from every major step.

## 13. Known risks

- Gateway and MCP components may have release-specific support and dependency boundaries.
- Operator installation success does not guarantee request-path correctness.
- A NetworkPolicy resource is not proof of isolation: Kubernetes policies are additive, and an operator-generated allow policy can keep a backend reachable.
- OIDC issuer reachability and CA trust are frequent failure points.
- User-created Gateway behavior may differ from installer-provisioned gateways.
- MaaS, MCP Gateway, and llm-d may use overlapping or release-specific Gateway API resources.
- Demo workarounds can be mistaken for product behavior unless the report labels them precisely.
- Customer credentials and model endpoints must never be committed to Git or emitted in logs.

## 13.1 Cluster remediation boundary

Gatekeeper may create its own namespace and apply layer-scoped configuration such
as backend NetworkPolicy, registrations, routes, and evaluation fixtures. It
must not uninstall, orphan, or upgrade cluster-wide operators as an implicit
side effect of a one-click run.

If the OpenShift ingress ClusterOperator reports that Service Mesh prevents
operator-managed Gateway API, the production profile must stop and identify:

1. active Service Mesh 2 control planes and member namespaces;
2. Service Mesh 3 installation and migration state;
3. Gateway and HTTPRoute ownership that must remain available; and
4. the explicit admin decision required: migrate the active mesh, dedicate a
   clean acceptance cluster, or accept an innovation-lane evaluation only.

This boundary keeps the one-click experience low-friction for the customer
without turning a Gateway-layer installer into an unreviewed cluster lifecycle
operation.

## 14. Immediate implementation sequence

1. Freeze this contract against the target OpenShift AI, OpenShift Connectivity Link, and MCP dependency versions.
2. Extract the existing runbook and demo checks into a deterministic preflight/validate/evaluate command set.
3. Define the first `LayerDeployment` resource and status phases.
4. Create the Gatekeeper GitOps application hierarchy and dependency waves.
5. Build the Gateway profile with explicit support-boundary labels.
6. Implement the authenticated MCP-to-MaaS evaluation.
7. Add evidence collection and downloadable diagnostics.
8. Rehearse the complete flow against a clean baseline.
9. Deliver the Saudi Aramco evaluation and capture feedback as a journal entry.

## 15. Official documentation map

The implementation must maintain a version-pinned documentation map beginning with:

- [Red Hat OpenShift AI 3.x Supported Configurations](https://access.redhat.com/articles/rhoai-supported-configs-3.x)
- [OpenShift AI 3.5 installation and deployment](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.5/html/installing_and_uninstalling_openshift_ai_self-managed/installing_and_deploying_openshift-ai_install)
- [OpenShift AI Models-as-a-Service](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.5/html/govern_llm_access_with_models-as-a-service/index)
- [OpenShift AI MCP Catalog](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.5/html/working_with_the_mcp_catalog/index)
- [OpenShift AI MCP Lifecycle Operator](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.5/html/working_with_the_mcp_catalog/enabling-mcp-lifecycle-management)
- [OpenShift AI llm-d Gateway API configuration](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.5/html/deploy_models_using_distributed_inference_with_llm-d/gateway-discovery-for-llmd_gateway-discovery)
- [Red Hat Connectivity Link MCP Gateway introduction](https://docs.redhat.com/en/documentation/red_hat_connectivity_link/1.4/html/mcp_gateway/mcp-gateway-introduction)

This map is a starting point. The final kit must pin every link and instruction to the exact release validated by Gatekeeper.
