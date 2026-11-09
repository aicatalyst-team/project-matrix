# Red Hat AI Agentic Stack One-Click Journey Journal

This journal is the working record for the end-to-end effort to create a Red Hat-centric, opinionated one-click installer for the horizontal layers of the Red Hat AI Agentic Strategy.

The journal is intentionally append-oriented. Each entry records context, decisions, evidence, unresolved questions, and the next concrete move. It is the project memory for the product, architecture, implementation, demos, customer feedback, and validation journey.

## North Star

Bring a technically sophisticated customer from an existing OpenShift AI installation to immediate, verifiable value on a specific Red Hat AI Agentic Strategy layer with one click.

The installer must make the experience simple without making the platform opaque. A customer should be able to:

1. Click one layer deployment.
2. Observe the documented installation path.
3. Understand what was installed and why.
4. Run a real validation and evaluation flow immediately.
5. Download the same scripts and evidence used by the installer for troubleshooting.
6. Follow the exact official Red Hat documentation for deeper investigation.

## Product Thesis

The product is not a generic self-service marketplace and not an opaque automation wrapper. It is a set of opinionated, Red Hat-centric Layer Evaluation Kits.

Each kit combines:

- preflight checks;
- ordered installation;
- documented configuration;
- readiness and conformance tests;
- a working reference evaluation;
- observable evidence;
- downloadable troubleshooting scripts;
- version and support-boundary information.

The end state is a single stack with two future dimensions:

- **Horizontal layers:** independently deployable Red Hat AI Agentic Strategy capabilities.
- **Vertical solutions:** later, specific use cases that consume horizontal capabilities through stable contracts.

Vertical solution design is intentionally deferred until the horizontal contracts and evaluation experiences are proven.

## Canonical Red Hat AI: Agentic Strategy Vocabulary

The following terms are the product vocabulary and should be used consistently in documentation, UI, manifests, demos, and code:

1. **Infrastructure** — OpenShift, RHEL AI, GPUs/TPUs, storage, networking, and cluster prerequisites.
2. **vLLM (Core)** — model serving, chat completions, and tool calling.
3. **llm-d** — disaggregated serving, inference routing, and distributed inference.
4. **OGX** — API translation, RAG, connectors, orchestration, and multi-provider backends.
5. **Gateway** — MaaS Gateway, MCP Gateway, inference routing, authentication, rate limiting, quotas, and policy.
6. **Secure Agent Onboarding** — Agent Harness, OpenShell Sandbox, SPIFFE/SPIRE, workload identity, and secure credentials.
7. **AgentOps** — deep tracing, evaluation, cost tracking, guardrails, audit, and operational evidence.
8. **BYOA** — Bring Your Own Agent, including LangGraph, CrewAI, ADK, Strands, and custom agents.

The runtime path is:

```text
Infrastructure
  -> vLLM (Core)
  -> llm-d
  -> OGX
  -> Gateway
  -> Secure Agent Onboarding
  -> BYOA
  -> AgentOps
```

Security, identity, policy, observability, and lifecycle management are cross-cutting concerns across the path.

## Project Code-Name Registry

The overarching internal code name is **Project Matrix**.

The name reflects the strategy’s “From Metal to Agents” direction: the project assembles the infrastructure, inference, security, gateway, agent, and operations layers into one usable stack.

The layer code names are:

| Official strategy layer | Internal code name | Intended meaning |
|---|---|---|
| Infrastructure | **Bedrock** | The OpenShift AI, RHEL AI, accelerator, storage, and network foundation. |
| vLLM (Core) | **Ember** | The model-serving core that provides the first live intelligence. |
| llm-d | **Flux** | Distributed inference flow, routing, and scale. |
| OGX | **Bridge** | The translation and orchestration bridge between models, data, APIs, and agents. |
| Gateway | **Gatekeeper** | The governed entry point for MCP, MaaS, inference, identity, quotas, and policy. |
| Secure Agent Onboarding | **Bastion** | Protected agent execution, identity, sandboxing, and credential isolation. |
| AgentOps | **Lens** | Evidence, tracing, evaluation, guardrails, cost, and operational visibility. |
| BYOA | **Loom** | The framework and agent integration surface that weaves customer agents into the stack. |

The first delivery is therefore:

> **Project Matrix: Gatekeeper** — the Red Hat AI Agentic Strategy Gateway Layer Evaluation Kit.

The code names are internal project identifiers. External deliverables should lead with the official strategy terms and use the code name as a supporting identifier, for example: “Gateway Layer — Project Matrix: Gatekeeper.” The code names must never obscure the actual Red Hat component names, support boundaries, or official documentation.

## Governing Ontology: The Project Matrix Rubric

Project Matrix is the governing rubric for interpreting the Red Hat AI and agentic landscape.

Every Red Hat AI effort, product, service, Operator, reference architecture, demo, partner integration, model workflow, agent framework, gateway, security capability, or customer solution must be rendered with respect to this layering system.

There are no orphan efforts. Each effort must be identified as one or more of the following:

- a standalone horizontal layer;
- a capability spanning multiple horizontal layers;
- a subset or implementation of a horizontal layer;
- a cross-cutting control such as identity, policy, observability, governance, or lifecycle;
- a vertical solution that consumes horizontal layer contracts;
- an external integration that connects to the stack through a defined capability contract.

The canonical analysis for any new Red Hat AI effort is:

```text
What is it?
  -> Which Project Matrix layer does it live in?
  -> Which other layers does it depend on?
  -> Which capabilities does it expose?
  -> Which layer evaluation proves its value?
  -> Which vertical solutions can consume it?
  -> What is its Red Hat support boundary?
```

If an effort does not fit cleanly, it must either be mapped to the closest existing layer or submitted as a proposed extension to the Project Matrix layer model. New terminology must not create a parallel architecture without an explicit relationship to the canonical stack.

This rubric is the project’s Red Hat-colored view of the agentic world: it is the lens used to discover, classify, compare, design, install, evaluate, document, and explain AI capabilities from infrastructure through agents and operations.

Every future artifact should carry layer metadata, at minimum:

- primary strategy layer;
- secondary layers;
- dependencies and capability contracts;
- evaluation path;
- code name, where applicable;
- support classification;
- relationship to the complete Red Hat AI: Agentic Strategy stack.

The stack is the reference architecture and the full-stack evaluation is the ultimate integration test. Individual projects may be small, specialized, or customer-specific, but they must remain legible as part of the whole.

## Operating Doctrine: Production and Preview in Parallel

The team intentionally works across both what is in production and what is in Technology Preview or Developer Preview. Preview capabilities are essential because they allow the team to understand, shape, demonstrate, and prepare customers for the future Red Hat AI Agentic Strategy.

Project Matrix must therefore carry two deliberate lanes through every layer and every future vertical:

### Production lane

The production lane contains capabilities that can be evaluated through a production-quality lens. It requires:

- supported versions and configurations;
- stable installation and upgrade behavior;
- security and isolation validation;
- operational health and recovery evidence;
- documented support boundaries;
- no dependence on an unmarked workaround;
- a claim appropriate for production use.

### Innovation lane

The innovation lane contains Technology Preview, Developer Preview, early-access, partner, community, and forward-looking capabilities. It requires:

- explicit preview labeling;
- pinned versions and known prerequisites;
- a working demonstration path;
- documented limitations and failure modes;
- a clear statement that preview behavior is not a production SLA;
- a migration or promotion path when the capability becomes supported.

The innovation lane is not second-class work. It is the mechanism by which the team can articulate and demonstrate future capabilities. It is also not allowed to masquerade as production readiness.

### Shared layer contract

Where possible, both lanes must use the same Project Matrix layer contract:

```text
Production implementation
        │
        ├── same capability contract ──> verticals and evaluations
        │
Preview implementation
```

The implementation may differ, but the customer-facing capability, dependency model, evaluation evidence, and support classification must remain legible.

Every Project Matrix artifact must identify:

- lane: `production` or `innovation`;
- support tier;
- exact component and image versions;
- prerequisites;
- known limitations;
- evaluation status;
- whether the result can be promoted into the production lane.

The two-lane model applies to the complete stack, not only to Gatekeeper. Every horizontal Layer Evaluation Kit and every future vertical solution must be able to show both the supported production path and the clearly bounded future-capability path when one exists.

## Founding Entry — 2026-10-14

### Context

The project grew out of work demonstrating MCP through the Red Hat stack, OpenShift AI, Red Hat base images, official documentation, and manual scripts. The Saudi Aramco audience valued the architecture and the scripts. The scripts were not viewed as throwaway demo glue; they were treated as useful troubleshooting and learning tools.

The central customer feedback was that the solution was too complicated to install, even for a highly capable technical audience. The complexity was in assembling and validating the documented platform path, not in understanding the value of MCP, MaaS, the gateway, or the end-to-end agent flow.

Relevant existing evidence in this repository:

- [Saudi Aramco MCP + MaaS demo story](aramco-mcp-lifecycle/SAUDI_ARAMCO_E2E_STORY.md)
- [MCP lifecycle runbook](aramco-mcp-lifecycle/MCP_LIFECYCLE_RUNBOOK.md)
- [MaaS/MCP round-trip demonstration](aramco-mcp-lifecycle/maas-mcp-roundtrip/README.md)
- [MCP gateway lifecycle demo](demos/mcp-gateway-lifecycle-demo.sh)

### Strategic decision

The first product effort will focus on horizontal, layer-centric one-click deployments. The first candidate layer is **Gateway**, with emphasis on MCP Gateway and MaaS Gateway, because it is directly connected to the customer feedback and provides an immediate evaluation path.

The one-click action must not merely install Operators. It must bring the customer to a meaningful, live evaluation of the selected layer.

### Saudi Aramco delivery commitment

Project Matrix: Gatekeeper will be developed as the first customer-facing proof of the overall method and delivered to Saudi Aramco as the Gateway Layer Evaluation Kit.

The delivery will include:

- one-click installation of the opinionated Gateway layer;
- MCP Gateway and MaaS Gateway integration;
- documented dependency and readiness handling;
- authenticated MCP-to-MaaS evaluation;
- live tool federation and model routing;
- observability and evidence of each request hop;
- the manual installation, validation, and troubleshooting scripts;
- generated diagnostics and support artifacts;
- direct mapping to official Red Hat documentation;
- an explicit distinction between supported, Technology Preview, partner, community, and demo-only components.

This delivery is the first realization of Project Matrix, not a one-off demo. The implementation pattern, evidence model, and layer contracts must be reusable for Bedrock, Ember, Flux, Bridge, Bastion, Lens, and Loom.

### Definition of a Layer Evaluation Kit

Every horizontal layer will eventually have the following experience:

```text
Preflight
  -> Install
  -> Configure
  -> Validate
  -> Evaluate
  -> Observe
  -> Diagnose
```

The kit must expose both a simple UI action and the underlying inspectable artifacts. The automation should generate or execute the same scripts that an advanced customer can download and run manually.

### Gateway layer target experience

The Gateway Evaluation Kit should make it possible to deploy and evaluate:

- MCP Gateway;
- MaaS Gateway;
- authentication and authorization;
- model endpoint routing;
- MCP tool federation;
- quotas and rate limits;
- telemetry and audit evidence;
- a sample MCP server;
- a sample MaaS-served model;
- a complete authenticated tool-to-model round trip.

The customer should finish with a working request path, validation results, examples, routes, logs, traces, and official documentation links.

### All-layer commitment

The Gateway layer is only the first implementation pilot. The same Layer Evaluation Kit approach applies to every horizontal in the Red Hat AI: Agentic Strategy. The overall strategy stack remains the eyes-on-the-prize reference throughout design, implementation, testing, demos, and customer evaluation.

Every layer must be useful by itself and must also connect cleanly to the layers above and below it.

| Strategy layer | Immediate evaluation outcome |
|---|---|
| **Infrastructure** | Confirm OpenShift AI, RHEL AI, accelerator, storage, networking, and identity readiness for the next layers. |
| **vLLM (Core)** | Deploy a known model and prove chat completions and tool calling through a working endpoint. |
| **llm-d** | Demonstrate distributed or disaggregated inference, routing behavior, capacity use, and measurable performance. |
| **OGX** | Prove API translation, model access, connectors, knowledge retrieval, RAG, and multi-provider behavior. |
| **Gateway** | Prove authenticated MCP and MaaS routing, federation, quotas, rate limits, and policy enforcement. |
| **Secure Agent Onboarding** | Prove agent identity, sandboxed execution, credential isolation, permitted tools, and denied actions. |
| **AgentOps** | Prove deep traces, evaluation results, guardrails, cost/token evidence, auditability, and operational health. |
| **BYOA** | Bring a supported example agent through the common stack contracts and prove that customer agents can use the platform without changing the platform layers. |

The full-stack evaluation must eventually follow the complete strategy path:

```text
Infrastructure
  -> vLLM (Core)
  -> llm-d
  -> OGX
  -> Gateway
  -> Secure Agent Onboarding
  -> BYOA
  -> AgentOps
```

The layer-specific evaluation is not complete until it answers two questions:

1. Can the customer use this layer immediately and understand its value?
2. Does this layer produce the capability required by the next layer in the Red Hat AI: Agentic Strategy path?

The final full-stack button will compose the validated Layer Evaluation Kits. It must not become a separate, untested installation path.

### Design principle

The installer must compress complexity, not conceal it.

The customer experience should be:

```text
One click
  -> documented installation
  -> visible progress and dependencies
  -> real validation
  -> immediate evaluation
  -> inspectable troubleshooting evidence
```

### Dependency principle

Horizontal layers will be modeled as a dependency graph, not as isolated buttons and not as a permanently flattened monolith.

Dependencies will be classified as:

- **Hard dependencies:** required before installation can proceed.
- **Capability dependencies:** required APIs or services that can be satisfied by more than one implementation.
- **Optional integrations:** enhancements that are detected and used when available.
- **Runtime dependencies:** services required for the evaluation or production request path.

Future verticals will declare required capabilities rather than directly installing Operators. The horizontal platform resolver will determine whether a capability is already present, install the appropriate Red Hat-centric layer, and bind the vertical to its stable contract.

### Success criteria

The first horizontal project is successful when a technically sophisticated customer can:

- start from the documented OpenShift AI baseline;
- click once to deploy the Gateway layer;
- understand what the installer did;
- see dependency and readiness status;
- run a real MCP-to-MaaS evaluation;
- inspect identity, gateway, model, tool, and telemetry hops;
- download and use the troubleshooting scripts;
- map every major step to official Red Hat documentation;
- distinguish supported behavior, Technology Preview behavior, and demo-specific extensions.

### Explicit non-goals for this phase

- Do not design the final use-case catalog yet.
- Do not expose arbitrary framework or Operator choices to the customer.
- Do not build an opaque installer that hides generated resources and scripts.
- Do not call a layer complete because its Pods are Running.
- Do not treat a demo-only workaround as a production-supported capability.

## Working architecture

The eventual control path is expected to be:

```text
OpenShift AI dashboard entry point
  -> Layer deployment controller
  -> declarative layer resource
  -> GitOps and Operator orchestration
  -> validation/evaluation runner
  -> evidence and troubleshooting bundle
```

The implementation should preserve the ability to run the same validation and diagnostic assets from the CLI. The UI is an approachable view of the proven path, not a replacement for it.

## Next milestone

Create the **Gateway Layer Contract and Evaluation Specification** covering:

- supported Red Hat components and support boundaries;
- prerequisites and capability dependencies;
- installation waves;
- required Custom Resources and configuration;
- validation scripts;
- reference MCP-to-MaaS evaluation;
- telemetry and evidence requirements;
- failure and rollback behavior;
- official documentation mapping;
- downloadable troubleshooting artifacts.

This specification is the first implementation boundary for the overall one-click horizontal project.

## Journal conventions

Future entries should record:

- date and milestone;
- customer or technical context;
- decisions made;
- evidence collected;
- files or demonstrations changed;
- unresolved risks;
- next action.

This journal should remain honest about the boundary between live, validated, Technology Preview, partner-supported, community-supported, and demo-only behavior.

## Environment Assessment — 2026-10-14

### Candidate cluster

The supplied IBM Cloud OpenShift cluster was authenticated read-only for Gatekeeper assessment. The credential was not stored in the repository or recorded in this journal.

### Positive findings

- OpenShift Server: 4.21.8.
- OpenShift AI Operator: 3.5.0, `DataScienceCluster/default-dsc` reports `Ready`.
- Three control-plane nodes are Ready.
- Worker and GPU capacity is present, including NVIDIA GPU allocatable resources.
- Default IBM Cloud block storage classes are present and dynamically provisionable.
- OpenShift AI components required for the Gateway evaluation are present, including MaaS/KServe, MLflow, Llama Stack/MCP lifecycle components, workbenches, TrustyAI, and GitOps.
- The MCP Gateway is Accepted and Programmed.
- The MCP Gateway HTTPRoutes are Accepted and Resolved.
- The two evaluation MCP servers are Ready and their registrations report Ready with 29 and 13 tools.
- The existing secured MCP edge rejects an unauthenticated request with HTTP 401, which is the correct first security signal.

Red Hat’s current Supported Configurations article lists OpenShift AI 3.5 on OpenShift 4.21 as supported. The article is the authoritative compatibility reference for this assessment; individual installation pages may lag the current support matrix.

### Production-quality blockers

The cluster is **not yet a clean production-quality acceptance baseline**:

1. The OpenShift `ingress` ClusterOperator is `Degraded=True` because the installed Service Mesh package prevents OpenShift from enabling operator-managed Gateway API.
2. Both Service Mesh 2 and Service Mesh 3 Operators are installed, which must be resolved into an intentional, documented strategy for the target Gatekeeper profile.
3. Multiple historical and current non-running or failed Pods exist across the cluster, including Gateway, Authorino, MCP lifecycle, logging, sandbox, and customer/Poc namespaces.
4. Failed CSV versions are present around the RHCL, Authorino, DNS, and Limitador dependency set, even though active versions report running in some namespaces.
5. The cluster is heavily shared and contains many unrelated experiments and stale workloads, making failure attribution and clean production-lens evidence difficult.
6. The direct MCP Gateway hostname returned HTTP 503 during the smoke test, while the existing secured edge returned the expected unauthenticated HTTP 401. The deployment path must make the intended edge and direct-gateway exposure explicit rather than relying on demo-specific routing.

### Assessment decision

Use this cluster for:

- Gatekeeper development;
- functional integration testing;
- the Saudi Aramco customer rehearsal;
- reproducing and documenting Gateway behavior;
- validating the one-click workflow against a realistic existing installation.

Do not use it yet for:

- final production-quality acceptance;
- a clean install benchmark;
- a supportability claim that ignores the ingress degradation;
- measuring Gatekeeper’s failure behavior without namespace and cluster noise controls.

### Remediation gate before production-quality certification

Gatekeeper’s production-lens test environment must have:

- no degraded ClusterOperators;
- an intentional and supported Service Mesh/Gateway API configuration;
- no failed active Operator versions in the Gatekeeper dependency set;
- no non-running Pods in the Gatekeeper namespaces;
- a dedicated or cleanly isolated test surface;
- a documented secured edge path;
- successful unauthenticated rejection and authenticated MCP-to-MaaS round trip;
- direct backend-bypass testing;
- correlated AgentOps evidence;
- a captured baseline report before and after installation.

This cluster remains valuable, but its official role is currently **Project Matrix development and customer-evaluation environment**, not **Project Matrix production-certification environment**.

## Implementation Entry — 2026-10-14 — Gatekeeper One-Click Slice Started

### Decision

Begin implementation with a profile-aware Gatekeeper runner rather than waiting
for the shared cluster to become clean. The installer must make the blockers
visible and enforce them as gates; it must not hide them by uninstalling
cluster-wide operators or silently changing the platform.

### Delivered

- Added `project-matrix/gatekeeper/gatekeeper.sh` with the tracked lifecycle:
  `preflight -> install -> validate -> evaluate -> diagnostics`.
- Added explicit `innovation` and `production` profiles.
- Added a `matrix-system` deployment record carrying Gateway layer, Gatekeeper
  code name, lane, profile, and phase metadata.
- Added optional Gateway-only NetworkPolicy hardening and native OIDC
  AuthPolicy rendering from a supplied issuer.
- Added production gates for degraded ingress, preview Gateway dependencies,
  and missing OIDC configuration.
- Reused the Saudi Aramco MCP-to-MaaS scripts as the inspectable evaluation
  path, while making their endpoint configuration portable across clusters.
- Added gitignored per-run evidence and diagnostics bundles.

### Current blocker evidence

The supplied OpenShift API endpoint is currently not resolvable from the
development workstation. No cluster mutation was attempted in this step. The
next live action is to restore API/DNS reachability, rerun Gatekeeper preflight,
and then resolve the ingress/Service Mesh/Gateway API conflict through an
intentional cluster-admin decision before production-lane acceptance.

### Lane posture

The innovation lane is the immediate Saudi Aramco rehearsal path. It can
demonstrate the real Gateway layer and preview capabilities with explicit
limitations. The production lane remains fail-closed until the platform
remediation gate passes.

## Live Implementation Entry — 2026-10-15 — Gatekeeper Innovation Install

### Action

The innovation profile was deployed to the supplied IBM Cloud OpenShift
cluster. The install was limited to Gatekeeper-owned state and the existing
Gateway-layer hardening artifact; it did not alter Service Mesh subscriptions,
operators, or the active Service Mesh control plane.

### Evidence

- `matrix-system` namespace created.
- Gatekeeper deployment record created with Gateway layer, Gatekeeper code name,
  innovation lane, and `gateway-evaluation` profile.
- `mempalace-allow-gateway-only` NetworkPolicy applied.
- OpenShift AI `DataScienceCluster/default-dsc` remained Ready.
- Gateway API CRDs and the existing `mcp-gateway` were present.
- MCP registrations were Ready with 29 MemPalace tools and 13 OpenShift MCP
  tools.
- The secured MCP edge rejected an unauthenticated initialize request with
  HTTP 401.

### Honest boundary

The install is an **innovation-lane evaluation**, not a production claim. The
run recorded warnings for degraded ingress, the preview MCP Gateway operator,
and the absence of a native AuthPolicy issuer configuration.

### Validator correction

The first validation pass incorrectly treated a Gateway API resource as
unavailable because it looked for `.status.phase`. Gateway API readiness is
condition-based; Gatekeeper now checks `Accepted=True` and `Programmed=True`.
This is exactly the kind of inspectable troubleshooting feedback the one-click
experience must preserve.

### Remaining production decision

The cluster has a healthy Service Mesh 2.6.17 control plane with active
members, including `praxis-verified`, while Service Mesh 3 is installed but
pending upgrade/transition. Removing the Service Mesh 2 subscription without a
migration plan could orphan or interrupt those workloads. The production gate
therefore remains correctly blocked until the team chooses and validates a
Service Mesh 2-to-3 migration or a clean dedicated Gatekeeper acceptance
surface.

## Product Decision — 2026-10-15 — Production/Preview Operating Switch

Clarification: the end-user `on/off` control is not for individual platform
capabilities. It is one operating-mode switch:

```text
Preview capabilities: OFF | ON
```

OFF selects the supported production path. ON selects the Technology/Developer
Preview and future-capability path on the same OpenShift AI instance. Both
lanes may be installed and maintained concurrently when their dependencies can
coexist; the switch controls the active implementation, route, or profile.

The UI must display the active mode and support boundary. A preview component
that replaces a production component on the active request path makes that path
preview while enabled. Where side-by-side operation is supported, toggling the
mode changes activation without destroying the inactive lane. The controller
must never uninstall shared Operators, delete customer data, or change
cluster-wide Service Mesh through this switch.

## Agenda Checkpoint — 2026-10-15 — Cross-Layer One-Click Control Plane

### Terminology correction

The next implementation is an architectural **horizontal slice**, not a
Project Matrix use-case vertical. It is the cross-layer one-click control plane
that every horizontal layer will use. Gatekeeper is its first Gateway-layer
adapter.

### Overall agenda

| Workstream | Status | Current position |
|---|---|---|
| Red Hat AI: Agentic Strategy rubric | Active | All work remains mapped to the eight canonical layers. |
| Production/preview same-instance model | Defined | One instance, explicit mode switch, dependency-aware coexistence. |
| Gatekeeper Gateway implementation | In progress | Innovation install is live; production and effective bypass gates remain visible. |
| Cross-layer one-click control plane | In progress | Controller, Gatekeeper Job seam, runner boundary, and evidence handoff are implemented; image mirroring and UI remain. |
| OpenShift AI UI | Pending control plane | Add the simple Production/Preview switch after the controller contract is stable. |
| Remaining horizontal layers | Planned | Reuse the same contract for Infrastructure through BYOA and AgentOps. |
| Use-case verticals | Intentionally deferred | Start only after the horizontal layer controls and dependencies are specific. |

### Next execution slice

Complete the reusable `LayerDeployment` flow by mirroring the pinned executor
image and connecting the OpenShift AI UI mode switch. The first usable flow
will be:

```text
OpenShift AI UI mode switch
  -> LayerDeployment desired state
  -> dependency-aware controller
  -> Gatekeeper Gateway profile
  -> status, evidence, and support boundary returned to the UI
```

This is the smallest cross-layer horizontal increment that proves the overall
one-click architecture without prematurely inventing use-case verticals.

## Technology Decision — 2026-10-15 — Kubernetes-Native Deployment Logic

Project Matrix will use a Kubernetes-native control plane for deployment logic:

- Go with Kubebuilder/controller-runtime for reconciliation;
- Operator SDK and OLM for Red Hat/OpenShift-native packaging;
- Argo CD and Kustomize for versioned production and preview profiles;
- Kubernetes Jobs, with Tekton where a multi-stage pipeline is justified, for
  validation, evaluation, and diagnostics;
- React/TypeScript and PatternFly for the OpenShift AI UI experience;
- typed dependency graphs plus CEL constraints for same-instance coexistence;
- Kubernetes Conditions, Events, Prometheus, OpenTelemetry, and MLflow for
  status and evidence.

The UI owns intent, the controller owns lifecycle coordination, Argo CD owns
profile resources, and Jobs own repeatable evaluation. The existing shell
scripts remain inspectable troubleshooting assets and the first Job
implementation. Terraform or Ansible may participate in Infrastructure, but
they will not be the inner orchestration engine for OpenShift AI layer
activation.

## Platform Clarification — 2026-10-15 — OpenShift AI Is the Contract

Project Matrix is not a generic Kubernetes installer. Its inherent platform is
Red Hat OpenShift AI Self-Managed on OpenShift. Portability means supporting
Red Hat OpenShift footprints—including public cloud, on-premises,
disconnected, and air-gapped environments—while preserving the OpenShift AI
operating model.

IBM ownership of Red Hat and HashiCorp is context for the toolchain, not a
runtime integration target. There is no IBM Cloud, watsonx, or other IBM
service dependency in Project Matrix. Terraform may provision infrastructure
where appropriate, and Ansible may automate hosts, registries, disconnected
content, and operations; neither replaces the OpenShift AI control plane or
the Kubernetes-native controller.

The priority order is Red Hat-supported OpenShift AI/OpenShift capabilities,
then upstream/open-source or downstream-compatible implementations where they
preserve the same layer contract and improve customer control. The controller
must preflight for OpenShift, OpenShift AI, the supported configuration,
required Operators, AI Dashboard integration, Gateway API, Routes, OAuth, SCC,
storage, and observability before mutation.

## Product Decision — 2026-10-15 — Dual-Lane Coexistence on One Instance

The one-click target for Project Matrix is now explicitly **one OpenShift AI
instance containing both production and Technology/Developer Preview
capabilities**, wherever the dependency graph supports coexistence.

This does not mean silently mixing support claims. The deployment planner must:

- install supported production components in the production lane;
- install preview and future-facing components in an isolated innovation lane;
- use separate namespaces, routes, labels, profiles, and evidence where
  required;
- show the support tier and exact version of every component;
- identify shared control-plane dependencies;
- fail before mutation when two requested capabilities are mutually exclusive;
- state whether preview capabilities are promotable to the production lane.

The same-instance model is the default goal. A separate cluster becomes an
exception only when a dependency cannot safely coexist or when production
certification requires an uncontaminated acceptance surface.

The current Gatekeeper cluster demonstrates why this resolver is necessary:
Service Mesh 2 owns live workloads while Service Mesh 3 is present but not yet
migrated, and the MCP Gateway is preview. The one-click UI must expose that
dependency conflict rather than presenting production and preview as if they
were interchangeable.

### Additional hardening finding

The direct-backend probe initially returned HTTP 200 after the standalone
Gateway-only NetworkPolicy was applied. The live MCP Lifecycle Operator creates
its own `mempalace` NetworkPolicy with an allow-all ingress rule, and Kubernetes
NetworkPolicies are additive. Tightening that generated policy was immediately
reconciled back by the operator. Gatekeeper therefore does not count the
presence of a NetworkPolicy as proof of isolation; the effective bypass probe
is now a required gate. The next secure-backend implementation must either use
an operator-independent deployment profile or gain a supported operator-level
network isolation control.

## Implementation Entry — 2026-10-15 — Project Matrix Control-Plane Scaffold

The first reusable control-plane increment is now implemented in
`project-matrix/controller`. It uses Go and controller-runtime, matching the
Red Hat/OpenShift-native technology baseline.

The controller currently:

- watches the `LayerDeployment` API;
- validates canonical layer/code-name identity across Infrastructure, vLLM
  (Core), llm-d, OGX, Gateway, Secure Agent Onboarding, AgentOps, and BYOA;
- resolves the single Production/Preview operating-mode contract and default
  Gateway profiles;
- rejects invalid modes, profiles, and layer identities before mutation;
- writes an auditable plan ConfigMap owned by the `LayerDeployment`; and
- publishes phase, active mode, support boundary, evidence reference, and
  explicit conditions.

This increment is intentionally plan-only. For Gatekeeper, the controller reports
`AdapterNotImplemented` rather than claiming that the Gateway layer is
installed. The existing Gatekeeper shell remains the inspectable execution
prototype until it is packaged behind a controlled Kubernetes Job adapter.

Verification completed:

```text
go test ./...   PASS
go vet ./...    PASS
```

The next executable seam is now present as a Gatekeeper Job adapter. When the
controller is configured with an explicit `GATEKEEPER_EXECUTOR_IMAGE`, a valid
Gatekeeper `LayerDeployment` creates a namespaced Job with a reviewed service
account contract, no embedded credentials, and the selected innovation or
production runner profile. Job status is reflected as `Installing`, `Ready`,
or `Degraded`. Without that image configuration, the controller remains
plan-only and cannot accidentally claim installation.

The next action is to package and mirror the executor image, define the
customer-reviewed runner RBAC, and connect the Job's generated evidence bundle
to the `LayerDeployment` evidence reference.

## Implementation Entry — 2026-10-15 — Gatekeeper Evidence and Runner Boundary

The Gatekeeper execution seam now includes the missing evidence and authority
boundaries:

- the Job passes no bearer token, OIDC secret, or customer endpoint in its
  manifest;
- the executor wrapper preserves the original `gatekeeper.sh` workflow and
  publishes `report.md`, `status.env`, and diagnostics to a namespaced evidence
  ConfigMap after every run, including failed runs;
- the `LayerDeployment.status.evidenceRef` points to that evidence ConfigMap
  when executor mode is enabled;
- a separate reviewed RBAC manifest gives the runner read-only observation
  access plus narrowly scoped writes for Gatekeeper evidence, backend
  NetworkPolicies, the Gateway AuthPolicy, and the temporary bypass probe; and
- optional evaluation fixtures remain outside the default runner authority.

The reference RBAC manifest parses successfully locally. Cluster-side
application remains a platform-admin action and was not performed in this
implementation pass. The controller and adapter tests, Go vet, shell syntax,
and repository whitespace checks pass.

Checklist position: the control-plane contract, optional Job execution path,
evidence handoff, and runner policy are implemented. The remaining control-plane
work is to build and mirror a pinned executor image, add the OpenShift AI UI
mode switch, and validate the complete path on the candidate cluster.

## Implementation Entry — 2026-10-15 — Gatekeeper Executor Packaging

The Gatekeeper executor was built locally from the Red Hat-based `Containerfile`.
The build initially exposed that the selected UBI Python runtime uses `dnf`, not
`microdnf`; the image was corrected and rebuilt successfully.

Verified locally:

- Red Hat OpenShift CLI copied from the OpenShift CLI image;
- Gatekeeper scripts and Saudi Aramco troubleshooting assets included;
- non-root image configuration (`USER 1001`);
- `/opt/project-matrix/bin/run-gatekeeper --help` succeeds; and
- the Kustomize profile renders the namespace and reviewed runner RBAC.

The local `:dev` image is not a production artifact. A customer registry digest
must be created and recorded before the controller's `GATEKEEPER_EXECUTOR_IMAGE`
is enabled for a production or innovation profile.

## Implementation Entry — 2026-10-15 — Same-Instance Dependency Resolver

The controller now resolves the active `LayerDeployment` set before it creates
an executor Job. The first resolver claims are explicit:

- one active owner per canonical layer;
- a shared OpenShift Gateway API capability may be consumed by multiple layers;
- the Gateway active MCP route cannot be simultaneously owned by separate
  Production and Preview `LayerDeployment` objects; and
- disabled intents do not claim dependencies.

This preserves the intended product model: one LayerDeployment exposes the
single end-user Production/Preview switch, while duplicate active owners are
blocked before mutation. The resolver is tested independently and through
controller reconciliation. Live cluster/operator discovery—especially the
Service Mesh 2/3 and Gateway API ownership state—remains a preflight provider
and is not inferred from this static intent resolver.

## Decision Entry — 2026-10-15 — External Reuse Review: Gateway, Ansible, and OpenClaw

The adjacent repositories and local OpenClaw/ODH work were reviewed against
Project Matrix's OpenShift AI-native boundaries.

The `openshift-ai-gateway-use-cases` repository is directly useful for the
first horizontal one-click layer. Its MCP Gateway, MCP server registration,
HTTPRoute, AuthPolicy/Authz, Kuadrant/Authorino, External Model, OGX, and
guardrails examples provide a strong source of capability fixtures,
conformance tests, evaluation flows, and troubleshooting scripts. They should
be normalized into Gatekeeper-owned, versioned profiles. The repository remains
a use-case kit and reference source; it is not itself the lifecycle controller,
and its raw manifests must not be copied into production without ownership,
namespace, version, credential, and support-boundary review.

The `openshift-ai-ansible` repository is useful primarily at the outer
Infrastructure/Bedrock boundary. Its role structure can inform optional
bootstrap for OpenShift AI, GPU/NFD, scheduling, observability, and related
cluster prerequisites. It is AWS-oriented and requires environment credentials
and Ansible collections, so it must remain an optional outer adapter. It is not
a hard dependency for the Project Matrix entry point where OpenShift AI is
already installed, and its assumptions must not leak into the controller or
dashboard.

The local OpenClaw installer and ODH Dashboard integration are highly useful
for the UI-side pattern: an authorized dashboard extension/BFF invokes a
Kubernetes action, an installer Job produces a validation/status resource, and
the dashboard presents progress and the next action. The module-federation
metadata, extension points, PatternFly presentation, Tech Preview labeling,
minimal RBAC, and troubleshooting/status experience are reusable.

The lifecycle authority must differ for Project Matrix. The UI should create or
patch a `LayerDeployment`; the Project Matrix controller should own dependency
resolution, Job creation, conditions, evidence, and remediation. The UI should
expose only the opinionated `Preview capabilities: OFF | ON` switch plus
phase, support boundary, conflicts, evidence, and troubleshooting—not a
generic self-service deployment form.

The reusable-material map is recorded in
`project-matrix/REUSE_MAP.md`. The next concrete reuse task is to classify the
Gateway repository's MCP examples as production-supported,
innovation/technology-preview, customer-supplied, or reference-only before
turning them into Gatekeeper profile sources.

## Decision Entry — 2026-10-16 — Aramock Hard Inspection and Layer Mapping

The referenced Red Hat GitLab repository was cloned through the supplied SSH
URL into `/Users/geraldtrotman/Virtualenvs/rhoai-customer-workflows` and
inspected at commit `e39026a31c8a41bf77edaa7b4a900326fddb7ef7`.

Aramock is materially relevant. It is a persistent RHOAI 3.5 customer-workflow
fixture suite covering MaaS, Gateway/Route readiness, direct Keycloak OIDC,
Authorino trust, service-account and group-based access, External Models,
LLMInferenceService simulation, optional Qwen model serving, Prometheus/MaaS
telemetry, AWS/IBM GPU capacity, and network/proxy/registry experiments. Its
Aramco Playwright workflows cover model deployment, service-account access,
external-model routes, and custom metrics.

The reuse decision is cross-layer rather than wholesale:

- **Gateway / Gatekeeper:** reuse MaaS/Gateway readiness, ExternalModel,
  MaaSModelRef, MaaSAuthPolicy, MaaSSubscription, OIDC, and Aramco acceptance
  flows as versioned fixtures and conformance tests.
- **Secure Agent Onboarding / Bastion:** reuse direct OIDC and Authorino trust
  validation as an optional identity integration profile; Keycloak is not a
  mandatory Project Matrix identity provider.
- **vLLM (Core) and llm-d:** reuse the simulator and Qwen paths as optional
  evaluation backends and dependency fixtures; they do not belong in every
  Gateway click.
- **AgentOps / Lens:** reuse MaaS telemetry, Prometheus, and custom-metrics
  checks as post-install evidence and acceptance validation.
- **Infrastructure / Bedrock:** reuse AWS/IBM MachineSet logic, image-source
  inventory, cluster proxy, DNS, CA, and rollback patterns only as outer,
  explicitly approved infrastructure adapters.

The most valuable engineering patterns are exact API-target guarding,
fail-before-mutation preflight, Aramock ownership labels, server-side dry runs,
bounded readiness gates, credential-free state snapshots, conflict-aware
restore, explicit destroy confirmation, and separation of temporary versus
persistent fixtures.

The primary boundary is equally important: `aramock/setup.sh` can enable MaaS,
create namespaces and identities, provision AWS/IBM GPU MachineSets, patch
dashboard configuration, and optionally change cluster-wide image or proxy
state. It must not be invoked wholesale by the Gatekeeper UI or embedded as the
Project Matrix controller. Project Matrix should decompose it into profile-owned
capabilities and reject unsupported or dangerous mutations before execution.

The immediate implementation consequence is to expand the Gatekeeper
profile-source catalog beyond the earlier Gateway examples. The first catalog
slice will cover MCP Gateway/OpenShift MCP, MaaS/OIDC, an optional namespaced
simulator, and the Aramco conformance workflow. GPU provisioning, cluster-wide
proxy/image policy, DNS cutover, and destructive MaaS Gateway reset remain
separate Bedrock operations with independent ownership, approval, and rollback.

Validation during the inspection pass: all Aramock shell scripts passed
`bash -n`; the repository's mock tests for cluster-proxy lifecycle,
Gateway/ClusterIP reset, Gateway network transitions, noProxy generation,
registry-source policy, and remote-proxy ACL rendering passed. ShellCheck was
not installed in the local environment, so no ShellCheck result is claimed.

The collaboration intent is now explicit: the Aramock team remains the owner
of its customer-workflow fixtures and acceptance knowledge, while Project Matrix
owns `LayerDeployment`, profile contracts, controller lifecycle, UI, and
evidence handoff. The initial integration model is a pinned Aramock revision
plus a shared capability/result contract, not a fork or an opaque runtime
dependency. The collaboration handoff is documented in
`project-matrix/ARAMOCK_COLLABORATION.md`.

## Implementation Entry — 2026-10-16 — Aramock-Derived Read-Only Conformance

The next checklist item is implemented as a non-mutating conformance seam.
Gatekeeper's innovation profile now invokes
`project-matrix/gatekeeper/conformance/aramock-gateway.sh`, which checks the MaaS
Gateway Accepted/Programmed state, the reference Aramock simulator,
MaaSModelRef resolution, MaaSAuthPolicy, MaaSSubscription, and an optional
MaaS endpoint response.

This uses Aramock's reference names, labels, and acceptance intent without
running `aramock/setup.sh`. Missing fixtures are advisory in the innovation
lane; an incomplete or unhealthy fixture is reported as a conformance failure.
The production profile does not run this fixture-specific check.

The optional-fixture behavior was smoke-tested with a mocked `oc` client:
absence of all Aramock marker resources returns the advisory exit code without
any mutation. Gatekeeper shell syntax, catalog validation, Go tests, Go vet, and
repository whitespace checks remain passing.

The checklist now has the source catalog and read-only Aramock conformance
complete. Remaining immediate items are the pinned executor image digest, the
OpenShift AI UI mode switch, and target-cluster production/innovation
validation.

## Implementation Entry — 2026-10-16 — Project Matrix Dashboard Mode-Switch Scaffold

The OpenShift AI UI increment is now implemented as a module-federated
dashboard extension scaffold under `project-matrix/ui/`. It follows the ODH
Dashboard/OpenClaw integration pattern for navigation, PatternFly presentation,
and modular-architecture API envelopes, while keeping Project Matrix's
controller as the only lifecycle authority.

The UI exposes the intended end-user experience for the first horizontal
slice: one `Preview capabilities: OFF | ON` switch on the Gateway/Gatekeeper
card. OFF selects `Production` and `gateway-production`; ON selects `Preview`
and `gateway-evaluation`. The first click applies the complete fixed Gatekeeper
intent, and later switch changes are idempotent updates to the same
`LayerDeployment`.

The UI reports phase, requested and active mode, support boundary, evidence
reference, and controller conditions. It does not expose arbitrary manifests,
namespaces, profiles, provider credentials, Aramock setup, or cluster
mutation controls.

The corresponding BFF contract is documented in `project-matrix/ui/bff/README.md`.
The BFF is deliberately a constrained authorization/transport boundary: it
must validate the fixed Gatekeeper shape and create or update only
`matrix-system/gatekeeper`. It must not become a second controller or invoke
Aramock wholesale. The extension is not yet claimed as live on an OpenShift AI
instance; BFF route implementation, dashboard feature registration, reviewed
RBAC, module build/install, and target-cluster validation remain open agenda
items.

## Product Principle Entry — 2026-10-16 — Red Hat Adoption Quality Bar

The project goal is not merely a successful installer or an internal demo. The
end state is a candidate Red Hat/OpenShift AI solution that can be reviewed,
supported, upstreamed, downstreamed, and operated with the same discipline as
other Red Hat platform capabilities.

That quality bar is now persistent across the full horizontal stack and all
future verticals. A layer is not complete because it works on one cluster. It
must have an OpenShift AI-native PatternFly experience, least-privilege and
explicit ownership, fail-before-mutation preflight, production/preview support
boundaries, upgrade and rollback behavior, disconnected and air-gapped content
provenance, observable evidence, automated hybrid-footprint validation, stable
open contracts, and a credible upstream/downstream promotion path.

Customer-derived material—including the Saudi Aramco workflows and Aramock
fixtures—will continue to influence acceptance and troubleshooting, but will
remain provenance-tracked and decomposed into reusable product capabilities.
Customer names and runtime-specific assumptions will not become hidden product
dependencies. This is the quality gate that remains in view while Gatekeeper is
completed and each subsequent Red Hat AI: Agentic Strategy layer is added.

## Implementation Entry — 2026-10-16 — Constrained Dashboard BFF

The next control-plane boundary is implemented. Project Matrix now has a narrow
Go BFF handler at `project-matrix/controller/bff/server.go` and a runnable
`controller/cmd/bff` binary. It authenticates the dashboard request through
the trusted reverse-proxy identity header, exposes only the fixed Gatekeeper
route, and returns the OpenShift AI modular-architecture response envelope.

The handler supports only:

- `GET` of `matrix-system/gatekeeper`, returning `{ "data": null }` for the
  first-click state; and
- an idempotent `POST` create-or-apply of the fixed Gateway/Gatekeeper intent,
  validating mode/profile pairing, `Enabled` desired state, and inactive-lane
  retention.

Unknown fields, customer-profile selection, namespace changes, arbitrary
profiles, and all other layers are rejected at the BFF boundary. The BFF does
not create Jobs, patch operators, alter Gateway API resources, or invoke
Aramock. Its reviewed starting permissions are limited to `get`, `create`, and
`patch` on `layerdeployments` in `matrix-system`, recorded in
`project-matrix/ui/bff/rbac.yaml`.

The BFF unit tests cover missing identity, initial empty state, create/update
of Production and Preview intent, and rejection of customer-profile or
namespace mutation. Go tests and vet pass with the isolated Project Matrix
cache. Dashboard reverse-proxy wiring, module build/install, executor image
provenance, and live target-cluster validation remain open.

## Implementation Entry — 2026-10-16 — Federated Dashboard Preview Scaffold

The Project Matrix UI is now shaped as a runnable ODH Dashboard remote rather
than only a component source tree. It includes the module-federation webpack
configuration, TypeScript project configuration, standalone entry point,
PatternFly asset handling, local development environment, and a `Makefile`
for starting the BFF and frontend. The local remote uses port 9104 and proxies
`/project-matrix/api` to the BFF on port 8082.

The production module metadata now points at the intended combined
`project-matrix-dashboard-bff` service in `matrix-system`. The BFF can serve
compiled remote assets when `BFF_STATIC_DIR` is set, allowing the dashboard
module asset path and constrained Project Matrix API path to share one reviewed
service endpoint. The ODH Dashboard host still needs the package wired into
its workspace and the combined image/service built and installed; this remains
an integration task rather than an implicit claim that the cluster dashboard
is already live.

## Boundary Entry — 2026-10-17 — Project Matrix Standalone Ownership

Project Matrix is now a standalone directory at
`/Users/geraldtrotman/Virtualenvs/project-matrix`. The Project Matrix source,
controller, UI, Gatekeeper profiles, journal, manifests, and preserved Gatekeeper
evidence no longer live in `mempalace-openshift`. The independent Aramco
lifecycle work remains in its own workspace; Gatekeeper consumes only an
explicit four-file vendor snapshot under `gatekeeper/vendor/`, with provenance
and review expectations documented at that boundary.

The move also corrected the executor image build contract. It now builds from
the Project Matrix root and places the Gatekeeper workflow at
`/opt/project-matrix/gatekeeper`, matching the wrapper and the controller's
executor contract. This is a repository-ownership correction, not a change to
the Red Hat AI: Agentic Strategy layer model.

## Implementation Entry — 2026-10-17 — Control-Plane Installation Package

The next horizontal-slice increment packages the control plane as a reviewed
OpenShift installation boundary at the Project Matrix root. The package now
includes the `LayerDeployment` CRD, Gatekeeper runner policy, controller RBAC,
controller Deployment, dashboard BFF RBAC, dashboard BFF Deployment, Service,
and health probes.

The controller and BFF release image contract is in
`controller/Containerfile`. The dashboard image contract is in
`ui/Containerfile.release`; it packages the BFF with the already-built
federated remote. The executor image remains intentionally empty in the
checked-in `controller-config.yaml`, keeping the controller plan-only until a
registry-approved immutable Gatekeeper digest is promoted.

The canonical install is now `oc apply -k .` from the Project Matrix root. The
package does not claim to register a new Dashboard module dynamically. Current
OpenShift AI Dashboard discovery is monorepo/build-time; the remaining UI
integration task is to register the Project Matrix package in the compatible
Dashboard source build and then promote the resulting combined image.

## Validation Entry — 2026-10-17 — Live Cluster Access and Baseline Verification

The supplied OpenShift AI API endpoint is the intended validation target, but
production quality cannot be inferred from the hostname alone. A read-only
login attempt rejected the supplied bearer token as invalid or expired. The
existing local kubeconfig also could not establish a reachable session to that
API endpoint. No Project Matrix resources were applied.

Project Matrix now includes `deploy/verify-cluster.sh`, which checks target
identity, OpenShift version, ClusterOperator health, and DataScienceCluster
presence without mutation.
The refreshed token now authenticates successfully. The live evidence is
OpenShift `4.21.8` with OpenShift AI platform `3.5.0` and a `default-dsc`
resource whose managed components include AI Gateway, MCP Lifecycle, KServe,
vLLM, llm-d, Llama Stack, and MaaS. The production gate is not yet clear:
the `ingress` ClusterOperator is degraded because the installed Service Mesh
operator prevents operator-managed Gateway API from being enabled. No Project
Matrix resources have been applied; resolving that platform ownership conflict
must remain an explicit Bedrock decision before a production Gatekeeper claim.

## Validation Entry — 2026-10-17 — Live Gateway Baseline and Edge Failure

Against the refreshed cluster session, the innovation preflight completed with
zero failures and three warnings. The live Gateway baseline is present:
`mcp-gateway-system/mcp-gateway` is Accepted and Programmed; its HTTPRoute is
Accepted with ResolvedRefs; the MCP registrations for `mempalace` and
`openshift-mcp` are Ready; both MCPServer backends are Ready; and MaaS model
references, MaaS auth policy, and MaaS subscription are Active/Ready.

The read-only validation still returned HTTP `503` from
`mcp-gateway.apps.ocp-gb.ibm.redhataicatalyst.com/mcp`. The response is the
OpenShift “application is not available” page. Internally, the Gateway
backend Service and EndpointSlices are ready, while the Gateway advertises
`06536a44-eu-gb.lb.appdomain.cloud`; the public hostname resolves through a
different load-balancer chain. This points to an edge/DNS exposure mismatch,
not a missing MCP registration. The innovation result is therefore useful for
internal structural evaluation but not an end-to-end public protocol pass.

Aramock-derived conformance also ran read-only and reported no failures, but
remains advisory because the Aramock fixture is not installed. No Aramock
resources were changed. The non-secret reports are preserved under
`evidence/live/20261017/`.

## Implementation Entry — 2026-10-17 — Podman Release-Path Hardening

The local Podman build path is now repaired and verified against the Red Hat
base-image chain. The user-level containers registry configuration contained
two orphaned fragments (`ure = false` and `lse`) after the `quay.io` and
`localhost:5000` entries. Those fragments were removed without changing the
registry policy itself. Podman now parses the file, reaches the running
Podman machine, and successfully pulls from `registry.access.redhat.com` and
`registry.redhat.io`.

The first real build then exposed two independent release-definition defects.
The Project Matrix Go module requires Go 1.25, so the controller and dashboard
Containerfiles now use the Red Hat UBI Go 1.25 builder. The UBI builder runs
non-root and cannot write to `/out` or `/src`; intermediate binaries now use
its writable `/tmp` path. The controller/BFF image and Gatekeeper executor image
both build successfully as local OCI images. Their local IDs are evidence of
build success only; they are not production release references.

The dashboard image remains intentionally host-build dependent. Its static
`ui/frontend/dist` bundle is not present in Project Matrix, and the frontend
imports OpenShift AI Dashboard internal packages. That bundle must be built in
the compatible Dashboard host workspace before the combined dashboard image
can be promoted.

The Gatekeeper help smoke test also exposed a non-root runtime mismatch: the
wrapper's unset `GATEKEEPER_RUN_ROOT` default resolved beneath the read-only
application tree. The wrapper now defaults to `/var/lib/project-matrix/runs`,
matching the controller-generated Job environment and image permissions. The
rebuilt image passes the documented `--help` startup test as UID 1001.

## Implementation Entry — 2026-10-17 — Dashboard Proxy Rewrite Compatibility

The OpenShift AI Dashboard module metadata rewrites `/project-matrix/api` to
`/api` before forwarding requests to the module service. The BFF originally
accepted only the browser-facing path, which would have produced a 404 after
real Dashboard proxying even though local development worked. The BFF now
accepts exactly the two known transport paths, registers both with its HTTP
multiplexer, and applies the same identity, validation, and namespace rules
to either path. A regression test covers the rewritten path. The BFF API
surface remains fixed to the Gateway/Gatekeeper LayerDeployment.

## Product Principle Entry — 2026-10-17 — Lean, Optimized, Robust, Secure

Project Matrix now has an explicit lean-platform quality gate. The objective is
the smallest coherent Red Hat AI: Agentic Strategy implementation that brings
an end user to value without unnecessary components, duplicated control
planes, excess privileges, or hidden customer-specific assumptions.

For every horizontal layer, “lean” means reusing installed OpenShift AI and
Red Hat capabilities wherever possible, keeping one authoritative lifecycle
path, bounding resource and image surfaces, and avoiding configuration choices
that belong to the end user. “Optimized” includes idempotent reconciliation,
bounded resource requests, reuse of platform services, and support for
disconnected/air-gapped packaging where applicable. “Robust” requires
fail-before-mutation preflight, explicit Production/Preview coexistence,
observable status and evidence, retry safety, rollback semantics, and clear
dependency reporting. “Secure” requires least-privilege RBAC, non-root
execution, pinned artifacts, trusted-proxy identity, secret-free evidence,
explicit network boundaries, and no implicit operator or DNS mutation.

This is now an acceptance gate at design, build, install, and live-validation
time. A layer is not complete because its happy path works once; it must meet
the lean/optimized/robust/secure bar while remaining faithful to its position
in the Red Hat AI: Agentic Strategy stack.

## Validation Entry — 2026-10-17 — Corrected Mesh Ownership Reassessment

The target cluster changed during validation. The earlier `praxis-verified`
namespace was subsequently purged, so it is no longer evidence of current
Mesh 2 ownership. A fresh inventory found that the active Service Mesh 2
member roll now contains `hermes-agent` and `tether-verified`.

`tether-verified` is an active Mesh 2 workload, not stale metadata: its Hermes
and Tether pods carry `istio.io/rev=basic`, the Mesh 2 sidecar status, the
`v2-6-istio-cni` network, and the Red Hat Service Mesh 2 `istio-proxy` image.
`hermes-agent` remains a member namespace but currently has no running pods.
The ingress diagnosis is therefore corrected from “praxis-verified is active”
to “Mesh 2 remains active through tether-verified and the Mesh 2 control
plane.” Removing the Mesh 2 subscription still requires either migrating
those workloads to Mesh 3 or explicitly retiring them; deleting only the
subscription would be an unsafe production mutation.

The public MCP endpoint remains HTTP 503, while the OpenShift AI Gateway API
resources remain Accepted and Programmed. This continues to separate the
operator health blocker from the independent public DNS/load-balancer
exposure issue.

## Implementation Entry — 2026-10-17 — Gateway API Compatibility Classification

The live cluster still reports the formal ingress `GatewayAPIInstallConflict`
because Service Mesh 2 remains installed. However, the Mesh 3 control plane,
the Gatekeeper GatewayClass, and the Gatekeeper Gateway are all Accepted and
Programmed. Mesh 2 removal is not warranted merely to clear a formal
condition while active Tether workloads still depend on it.

Gatekeeper production preflight now classifies this exact condition as a
non-blocking compatibility warning when those functional Gateway API checks
pass. Any other ingress degradation, or a failure of those checks, remains a
production failure. The condition and its exception are preserved in the
evidence report so platform health is not hidden or falsely represented as
fully green.

The live production preflight confirmed the behavior: ingress emitted one
compatibility warning rather than a failure, while the remaining failure was
the separately classified preview/external Gateway dependency. This means
Mesh 2 removal is no longer a Project Matrix production prerequisite. It remains
an independent platform-lifecycle decision only if the broader cluster should
eliminate the formal operator condition.

## Release Entry — 2026-10-17 — aicatalyst Image Promotion

Project Matrix controller and Gatekeeper images are now promoted to the
canonical `quay.io/aicatalyst` repositories and mirrored into the target
cluster's managed OpenShift registry. Immutable references are recorded in
`deploy/IMAGE_RELEASE_LOCK.md`. No credentials are stored in the repository.
The dashboard image remains pending the OpenShift AI Dashboard host build.

## Validation Entry — 2026-10-17 — Post-Migration Gatekeeper Assessment

The platform migration is complete and was revalidated against the live
OpenShift AI instance. The ingress ClusterOperator is now Available=True,
Progressing=False, and Degraded=False. Service Mesh 2 subscriptions,
control-plane resources, and member namespaces are gone. Mesh 3 now provides
healthy `openshift-gateway` and `tether-mesh` instances, and the migrated
Tether workloads are running on revision `tether-mesh-v1-27-3`.

The OpenShift AI `default-dsc` remains Ready. GatewayClasses and the
`mcp-gateway`, data-science, and MaaS Gateways are Accepted and Programmed.
Gatekeeper innovation preflight and read-only validation both pass with zero
failures. This clears the ingress migration blocker and allows Project Matrix
to continue through the final Gatekeeper acceptance work.

The Gatekeeper production preflight now has two remaining failures: the MCP
Gateway subscription is explicitly on the `preview` channel (`mcp-gateway`
operator v0.7.1, Tech Preview), and no approved OIDC issuer has been supplied.
The public MCP hostname also continues to return HTTP 503, so the external
DNS/load-balancer edge and authenticated protocol round trip remain open.

## Validation Entry — 2026-10-17 — Production Gate Narrowed

The live Keycloak instance exposes a valid OIDC discovery document for the
candidate issuer:

`https://mcp-keycloak.apps.ocp-gb.ibm.redhataicatalyst.com/realms/mcp`

Using that issuer candidate and the configured MCP endpoint, Gatekeeper
production preflight now passes the OpenShift AI DataScienceCluster, Gateway,
ingress, and OIDC configuration checks. It has one remaining failure: the
MCP Gateway package catalog exposes only the `preview` channel, and the
installed CSV is explicitly named `MCP Gateway Operator (Tech Preview)`.

The external edge remains independently unresolved. DNS for
`mcp-gateway.apps.ocp-gb.ibm.redhataicatalyst.com` resolves through
`402847df-eu-gb.lb.appdomain.cloud`, while the live Gateway Service advertises
`06536a44-eu-gb.lb.appdomain.cloud`; the public request remains HTTP 503.

Project Matrix can now proceed through Gatekeeper production hardening, but the
Gateway layer cannot be called fully production-ready until the MCP Gateway
support boundary is resolved and the public edge returns the expected
authenticated protocol behavior with an approved short-lived credential.

## Remediation Entry — 2026-10-18 — Live Gateway DNS Exposure Restored

The remaining public-edge failure was fixed against the live OpenShift AI
cluster. The MCP Gateway resource was already Accepted and Programmed, and its
dedicated Service load balancer was healthy at
`06536a44-eu-gb.lb.appdomain.cloud`. The public hostname had instead followed
the cluster wildcard record to the default ingress load balancer, producing the
OpenShift HTTP 503 page.

An exact `ingress.operator.openshift.io/v1/DNSRecord` named
`openshift-ingress-operator/mcp-gateway` now maps
`mcp-gateway.apps.ocp-gb.ibm.redhataicatalyst.com` to the Gateway’s advertised
load-balancer hostname. The OpenShift DNS provider reported `Published=True`;
after propagation, the public hostname resolved to the dedicated load
balancer. The public protected-resource discovery endpoint returned HTTP 200,
while the cluster-wide `*.apps` wildcard remained unchanged.

The remediation is now part of Gatekeeper’s one-click install path. When the
profile enables `GATEKEEPER_MANAGE_GATEWAY_DNS=1`, Gatekeeper derives the listener
hostname and programmed Gateway address, reconciles only that exact DNSRecord,
waits for the provider’s Published condition, and records the result. This is
an idempotent operator-owned mutation, not an unmanaged DNS edit.

The post-remediation live checks show all OpenShift ClusterOperators healthy,
the DNSRecord Published, and the public protected-resource discovery endpoint
returning HTTP 200. Production preflight is now reduced to the actual support
and security boundary: the cluster catalog exposes only the MCP Gateway Tech
Preview channel, and the native OIDC policy path still requires compatibility
fixing on that installed version. The production profile therefore fails
closed until a supported channel (or an explicitly approved production
exception), a compatible enforced OIDC policy, and an approved short-lived
credential are available. Innovation validation passes with zero failures and
records the unauthenticated/authenticated evidence gap without
misrepresenting the preview stack as production.

## Remediation Entry — 2026-10-18 — HTTPS and AuthPolicy Boundary

The live MCP Gateway listener was converted from HTTP to HTTPS on port 8443.
Gatekeeper uses the existing OpenShift wildcard certificate through a scoped
Gateway API `ReferenceGrant`; it does not copy or expose the private key. The
Gateway remained Accepted and Programmed, its Service changed to
`appProtocol: https`, and the public protected-resource endpoint returned
HTTP 200 over TLS.

The first HTTPS shape added a hostname constraint and correctly exposed a
Gateway API nuance: the MCP registration routes use internal backend
hostnames, so the constrained listener made both registrations NotReady. The
listener is now HTTPS but hostname-less, preserving the wildcard certificate
for public SNI while allowing the existing backend routes to match. Both
registrations returned Ready=True again with 29 and 13 tools respectively.

The native OIDC AuthPolicy was then tested with the verified cluster Keycloak
issuer. The policy reconciled as Accepted and Enforced, but the installed MCP
Gateway Tech Preview path returned HTTP 500 from the Kuadrant Envoy WASM
external processor instead of the required HTTP 401 challenge. The policy was
removed immediately so the live MCP endpoint returned to a healthy HTTP 200
initialize response. Gatekeeper now requires the AuthPolicy to be both Accepted
and Enforced in the Production lane, and the remaining compatibility issue is
explicitly tracked rather than treated as secure by implication.

## Contract Entry — 2026-10-18 — Production Is the Safe Default

The Production/Preview contract is now consistent across the user interface,
BFF, controller planner, Gatekeeper Job adapter, and standalone Gatekeeper shell.
Production is selected when no mode or profile override is supplied. The
Technology/Developer Preview lane is explicit: the dashboard toggle, a
Preview `LayerDeployment`, or `--profile innovation` must select it. This
prevents an unqualified command or first-click deployment from silently
activating preview capabilities.

## Validation and Hardening Entry — 2026-10-18 — Effective Backend Isolation Is a Gate

The live validation pass rechecked the target OpenShift AI instance after the
HTTPS and DNS remediation. The production profile correctly selected
`gateway-production` by default and recorded these live results: OpenShift AI
DataScienceCluster Ready, Gateway Accepted/Programmed, ingress not degraded,
the exact Gateway DNSRecord Published, and the Gateway listener using HTTPS.

Production still fails closed for two previously known boundaries: the
installed MCP Gateway is delivered through a Tech Preview channel, and the
native OIDC AuthPolicy is not currently Accepted/Enforced because the tested
policy path returned HTTP 500 instead of the required unauthenticated 401
challenge.

The Preview validation also exposed a real security issue rather than a test
artifact. The MemPalace backend has an operator-generated `mempalace`
NetworkPolicy whose ingress rule has no `from` selector, so it permits direct
in-cluster access. Gatekeeper’s additive gateway-only policies cannot override
that rule because Kubernetes NetworkPolicies are additive. The temporary
in-cluster probe reached the backend with HTTP 200, and the Preview validation
therefore failed the direct-bypass check.

Gatekeeper now treats effective backend isolation as a Production preflight gate;
checking only that a NetworkPolicy object exists is insufficient. The
innovation install path reconciled the scoped policy documents, but the
operator restored the permissive generated rule. This remains an explicit
Gateway-layer blocker until the MCP Lifecycle Operator exposes a supported
policy control, the backend is moved to a policy-controllable deployment
profile, or an approved mesh/administrative isolation mechanism is selected.

The same pass also corrected Gatekeeper’s evidence root so standalone runs write
under Project Matrix’s own `.gatekeeper-runs/` directory instead of the parent
`Virtualenvs` directory. Controller tests remain green with a writable Go
cache. No production claim is made while the support, identity, or effective
isolation gates remain open.

## Architecture Decision Entry — 2026-10-18 — Platform-Admin Isolation Boundary

The target OpenShift version exposes the native
`policy.networking.k8s.io/v1alpha1` `AdminNetworkPolicy` API. This is the
appropriate platform-level mechanism to enforce a Gateway-only ingress rule
when the MCP Lifecycle Operator continues to reconcile a permissive
namespaced NetworkPolicy; ordinary Kubernetes NetworkPolicies are additive and
cannot override that allow rule.

Project Matrix will not create this cluster-scoped policy implicitly from the
Gatekeeper click. Both the Production and Preview profile contracts currently
set `clusterWideMutationsAllowed=false`. The production design therefore has a
reviewed platform-administrator prerequisite option: select the MemPalace
backend pods, allow TCP/8000 only from `mcp-gateway-system`, and deny other
cluster-local sources. Gatekeeper will validate the resulting effective policy
and the bypass probe before accepting the Gateway layer.

This preserves the Red Hat-centric one-click experience while keeping the
boundary explicit: the click may reconcile the namespaced Gateway layer, but it
must not silently impose a cluster-wide administrative network control on an
existing OpenShift AI instance. The remaining implementation is to package
that reviewed prerequisite and obtain platform-owner approval, then re-run both
lanes against the live backend. The prerequisite is now packaged at
`gatekeeper/manifests/mempalace-adminnetworkpolicy-prerequisite.yaml` and passed
server-side validation against the live OpenShift API without being created.

## Remediation Entry — 2026-10-18 — Effective Isolation Accepted

The reviewed AdminNetworkPolicy was applied to the live target cluster after
the platform-admin boundary was explicitly accepted. The first manifest
revision used priority 100, which the target cluster rejected because its
OVN-Kubernetes implementation accepts priorities 0–99. The manifest was
corrected to priority 50, reapplied, and reported `SetupSucceeded` on every
cluster node.

The Gatekeeper gate was updated to recognize the ready named AdminNetworkPolicy
as effective isolation while continuing to detect a restrictive namespaced
NetworkPolicy when one is available. The underlying MCP Lifecycle Operator
policy remains permissive, but the administrative policy now enforces the
Gateway-only TCP/8000 boundary above it.

The validator’s temporary probe handling was also corrected: the normal
`oc run --rm` deletion message no longer masquerades as an HTTP result. The
innovation validation now completes with zero failures and two expected
warnings: no bearer credential was supplied, and the Preview lane deliberately
does not enable native OIDC. The default Production preflight now has two
remaining failures, exactly the MCP Gateway Tech Preview support dependency
and native OIDC AuthPolicy enforcement. Effective backend isolation is now a
passing production gate.

## Support Boundary Entry — 2026-10-18 — MCP Gateway Release Qualification

The support decision is now formalized rather than inferred from the presence
of a healthy operator. Red Hat OpenShift AI 3.5 release documentation identifies
the MCP Gateway Operator as an optional external Technology Preview prerequisite
for MCP management workflows. The target cluster is running
`mcp-gateway.v0.7.1` from its `preview` channel, so Project Matrix records this
as a Production blocker and a valid Preview-lane dependency.

The native OIDC test was repeated with the verified Keycloak issuer and
cluster-local JWKS endpoint. The AuthPolicy reported `Accepted=True` and
`Enforced=True`, but an unauthenticated POST to the public HTTPS MCP endpoint
returned HTTP 500 rather than the standard 401 challenge. Removing only the
temporary AuthPolicy restored HTTP 200 after policy detachment. This isolates
the defect to the installed Gateway/Kuadrant data path; changing the issuer URL
or adding custom response bodies does not make this release production-safe.

Gatekeeper’s profile catalog now carries the installed version, channel, support
tier, evidence source, and explicit Production decision. Preflight also
separates the MCP Gateway support gate from the Red Hat Service Mesh prerequisite
instead of labeling every external CSV as one undifferentiated blocker. The
remaining work is to obtain a supported Gateway release/channel or an approved
Production exception, then resolve the AuthPolicy 500/401 compatibility issue
and run a positive authenticated test with an approved short-lived credential.

## Architecture Decision Entry — 2026-10-18 — Current-Instance First, Upgrade-Aware by Contract

The Gateway one-click cannot assume that every customer has the authority,
maintenance window, disconnected-content path, or operational appetite to
upgrade OpenShift or OpenShift AI before receiving value. “Upgrade first” is
therefore not part of the end-user contract.

Gatekeeper now has two explicit lifecycle paths. The default is the
current-instance path: discover the installed OpenShift AI release, OLM
channel, approval mode, operator/API versions, and DataScienceCluster state;
resolve the compatible Gateway profile; then install and validate against that
known baseline. A newer manual-approval InstallPlan is evidence of an available
future state, not permission for Gatekeeper to approve it and not an automatic
blocker to a compatible current state.

The second path is for a platform-owned upgrade. The read-only
`upgrade-preflight` command captures a machine-readable compatibility baseline.
After the platform team performs its documented upgrade, `upgrade-postcheck`
compares operator and CRD/API transitions, checks OLM and ClusterOperator
stability, verifies OpenShift AI readiness, and reruns the actual Gateway
preflight and validation. It does not approve InstallPlans, mutate OLM
Subscriptions, execute upgrades, or roll back the cluster.

The live rehearsal exposed why this must be bounded and evidence-driven:
cluster-wide CSV discovery was not reliable on the target API path, so the
inventory was changed to use configurable namespace-scoped operator queries.
The cluster also has manual-approval plans for future OpenShift AI and related
operator states. Gatekeeper reports those as customer-controlled warnings while
continuing to block only active transitions, failed non-copy operator states,
unhealthy platform state, unsupported dependencies, or failed Gateway
conformance.

This preserves the Red Hat AI: Agentic Strategy layering model: the Gateway
layer owns its compatibility evidence and post-upgrade revalidation, while
OpenShift and OpenShift AI/OLM retain ownership of platform lifecycle changes.
The same Production/Preview toggle remains independent of upgrades. Preview
may select future capabilities, but it never silently changes the platform
release or approval policy.

## Hardening Entry — 2026-10-18 — Production Auth Challenge Must Fail Closed

The next production-closure action tightened Gatekeeper’s protocol gate. A
native OIDC `AuthPolicy` reporting `Accepted=True` and `Enforced=True` is not
proof that the data plane is compatible. The MCP client contract requires an
unauthenticated HTTP 401 challenge; the target preview path previously
returned HTTP 500.

Gatekeeper now treats every unauthenticated response other than HTTP 401 as a
Production failure. HTTP 503 remains identified as public-edge unavailability,
while HTTP 500 and any other response are identified as an AuthPolicy/data-plane
compatibility failure. The Preview lane continues to record the response as a
warning so future capability evaluation remains possible without weakening the
Production claim.

## Live Execution Entry — 2026-10-19 — Gatekeeper Production Gate Rehearsal

Using the supplied OpenShift AI instance, Gatekeeper completed a live production
preflight. OpenShift AI, Gateway programming, HTTPS, DNS publication, ingress
health, and effective backend isolation passed. The Production lane correctly
retained two blockers: MCP Gateway remains a Technology Preview dependency and
the native OIDC AuthPolicy is not Accepted/Enforced.

The live protocol validator then exercised the fail-closed path. The public
MCP request did not produce the required HTTP 401 challenge (the local probe
timed out with HTTP 000), so validation failed rather than treating reachability
or a non-401 response as authentication success. The in-cluster backend bypass
probe returned 000 and passed as blocked. No AuthPolicy or operator mutation
was performed. Static shell/catalog checks and the complete controller Go test
suite passed.

This closes the execution for the current unsupported baseline, not the
Production acceptance gate. The next required input is a supported MCP Gateway
release/channel or an explicitly approved Red Hat/customer exception, followed
by a compatible AuthPolicy path and a short-lived authenticated MCP test.

## Architecture Evidence Entry — 2026-10-19 — Aramco Operational-Burden Contract

Saudi Aramco validation sharpened the purpose of Project Matrix. The Gateway
horizontal must absorb the complexity of listener topology, router authority
rewrites, Envoy same-listener hairpinning, operator scope, TLS, exposure, and
service discovery. The customer should evaluate MCP, MaaS, and agent behavior;
they should not have to reverse-engineer the platform's hidden assumptions.

The Aramco findings are therefore promoted into Gatekeeper acceptance criteria.
The reference layout must use the public and `*.mcp.local` paths on the same
listener port, resolve the actual Gateway Service rather than assume an
Istio-suffixed name, ensure extension section names exist, and generate only
fields served by the installed HTTPRoute CRD. It must explicitly handle
LoadBalancer versus ClusterIP and OpenShift Route exposure, discover the
customer TLS Secret, report controller and CSV-copy scope, omit credentials
for unauthenticated backends, and verify registration plus the complete
authenticated MCP path.

This is the Red Hat AI: Agentic Strategy principle in executable form: a
horizontal layer creates immediate evaluable value by packaging the supported
and preview-aware infrastructure contract, while preserving platform-owner
boundaries and making every failure diagnosable. Aramock remains the source of
customer-workflow evidence where it is applicable; it is not copied as a
second control plane.

## Implementation Entry — 2026-10-19 — Complete MCP Protocol Proof

Gatekeeper validation previously stopped at an unauthenticated edge check and a
single `initialize` request. It now supports the Aramco acceptance sequence:
registration readiness, authenticated `initialize`, authenticated
`tools/list`, and an explicitly approved authenticated `tools/call`.

The call is intentionally opt-in through `GATEKEEPER_MCP_TOOL_NAME` and
`GATEKEEPER_MCP_TOOL_ARGUMENTS_JSON`; Gatekeeper does not invent a tool or invoke
an operation that might mutate customer state. Responses are inspected for
JSON-RPC shape and tool inventory, while bearer tokens and response bodies are
excluded from evidence.

The listener, service-discovery, CRD-schema, exposure, TLS, operator-scope,
credential, and protocol requirements from the Aramco findings are now
recorded as Gateway horizontal acceptance gates in `AGENDA.md`. The remaining
implementation work is to add discovery/reconciliation checks for those
topology assumptions and to validate the complete sequence against the
supported/preview profiles on the live OpenShift AI instance.

## Live Topology Entry — 2026-10-19 — Reference Layout Confirmed

The refreshed live inspection confirmed the target instance is using the
working topology Aramco described: the `mcp` listener is HTTPS on port 8443,
the extension targets the existing `mcp` section, its `privateHost` resolves
to the generated `mcp-gateway-data-science-gateway-class` Service, and the
private path uses the same 8443 port. The Gateway Service is intentionally
`LoadBalancer` on this cluster. Existing HTTPRoutes contain no unsupported
`spec.rules[].name` fields.

Gatekeeper now checks each of those facts instead of assuming them. The live
production preflight passed all topology, OpenShift AI, ingress, DNS, TLS, and
isolation checks; it retained only the two previously established Production
blockers: MCP Gateway Technology Preview support status and missing enforced
native OIDC AuthPolicy. This is the desired diagnostic shape: a customer sees
the precise support/security gates rather than a generic discovery or
tools/call failure.

## Support Boundary Entry — 2026-10-19 — No Supported Channel on Current Instance

The live OLM package manifest was inspected rather than assuming that a newer
Gateway channel existed. The `mcp-gateway` package exposes only the `preview`
channel, and the installed CSV is `mcp-gateway.v0.7.1`. No supported channel
was available to select on this instance. Red Hat documentation continues to
classify MCP Gateway as Technology Preview, so Gatekeeper correctly retains the
Production blocker.

Gatekeeper now supports an explicit governance path without confusing it with
support: `GATEKEEPER_SUPPORT_EXCEPTION_FILE` accepts a time-bounded,
version/channel-matched `GatekeeperProductionException`. The report records the
approval reference, approver, expiration, and file digest. It does not claim
Red Hat SLA coverage, bypass AuthPolicy/protocol gates, or enable Preview for
an end user.

The live production preflight also now requires the documented internal
`mcps` listener for authenticated tool authorization. The target Gateway has
only the public `mcp` listener, so this is a newly explicit blocker. The
rendered native AuthPolicy passes server-side API dry-run, but it has not been
applied because the previous runtime rehearsal returned HTTP 500 instead of
the documented unauthenticated HTTP 401. A supported/approved AuthPolicy path
and short-lived credential remain required before authenticated
`initialize`/`tools/list`/`tools/call` evidence can be claimed.

## Delivery Entry — 2026-10-19 — Dashboard Package and Quality Closure

The non-gating delivery slice is now packaged as an independent Project Matrix
boundary. The OpenShift AI Dashboard metadata exports the `projectMatrix`
federated module, registers **Agentic Platform → Red Hat AI: Agentic Strategy**,
and maps the authorized `/project-matrix/api` proxy to the fixed
`matrix-system/project-matrix-dashboard-bff:8082` Service. The BFF remains
constrained to the platform-owned Gatekeeper intent and the existing controller;
the browser cannot submit arbitrary manifests, namespaces, profiles, or
customer workflows.

The remote production build was aligned with the current ODH Dashboard host's
Module Federation toolchain. It builds successfully, emits `remoteEntry.js`
and `mf-manifest.json`, and is checked by the project-owned host-integration
validator. Production output now omits source maps by default, reducing the
standalone artifact from approximately 7.7 MiB to 2.4 MiB; `SOURCE_MAPS=true`
remains available for a diagnostic build. The host shares React, Router,
PatternFly, and Dashboard plugin dependencies at runtime.

The lean/optimized/robust/secure review is recorded in
`evidence/gatekeeper-delivery-quality-2026-10-19.md`. Kustomize rendering,
controller/BFF tests, Gatekeeper syntax/catalog checks, and the federated host
contract all pass. The combined Dashboard host build and immutable dashboard
BFF digest are intentionally still host-release actions, not hidden claims of
completion. The live MCP Gateway support, `mcps` listener, native AuthPolicy,
and authenticated protocol gates remain separate Gatekeeper production gates.

## Live Security Entry — 2026-10-19 — Gateway Support and Authentication Gates

The live Gateway was corrected against the Saudi Aramco/reference topology.
The public `mcp` listener and internal `mcps` listener now share HTTP port
8443; MCP backend routes use `*.mcp.local` and `sectionName: mcps`; public TLS
terminates at an OpenShift edge Route; and the exact DNSRecord points at the
OpenShift router load balancer. This avoids the mixed HTTP/HTTPS filter-chain
conflict caused by putting public TLS and internal rerouting on the same raw
Gateway port.

The security failure was then traced to the generated Envoy auth cluster. The
MCP Gateway's Kuadrant cluster connected to Authorino port 50051 without the
OpenShift service-CA TLS transport socket, while Authorino was serving TLS.
Authorino logged the definitive failure: `client sent an HTTP request to an
HTTPS server`. The Red Hat OpenShift AI integration point was used to resolve
this: `security.opendatahub.io/authorino-tls-bootstrap=true` caused the ODH
model controller to create the operator-owned `mcp-gateway-authn-ssl`
EnvoyFilter with the service-CA trust path. `opendatahub.io/managed=false`
keeps the custom Gateway from receiving unintended MaaS AuthPolicy rules while
retaining the Red Hat TLS bootstrap.

The resulting live proof is complete for the installed OpenShift TokenReview
path: unauthenticated `/mcp` returns HTTP 401 with `WWW-Authenticate: Bearer`;
a short-lived service-account token completes `initialize` with a session,
`tools/list` returns 49 tools, and the non-destructive `namespaces_list`
`tools/call` returns HTTP 200 with `isError=false`. No credential or response
body is persisted in evidence.

This closes the runtime Gateway/AuthPolicy gate for OpenShift TokenReview. It
does not erase the support boundary: the installed MCP Gateway remains on the
Technology Preview channel with no supported OLM channel on the instance. It
also does not promote native OIDC: the earlier OIDC policy returned HTTP 500
on this preview release and remains a customer-identity compatibility gate
until an approved issuer and short-lived validation credential are supplied.

## Gate Audit Entry — 2026-10-19 — Production Classification Hardened

Gatekeeper’s live gate audit now distinguishes the two authentication paths rather
than treating any `Accepted=True`/`Enforced=True` AuthPolicy as OIDC. The live
`mcp-auth-policy` uses OpenShift Kubernetes TokenReview and is proven by the
complete unauthenticated-401 plus authenticated MCP protocol sequence. The
production preflight now inspects the policy rule itself and will only report
native OIDC as ready when the configured issuer is present and matches the
active JWT rule. This prevents a TokenReview policy, stale policy, or unrelated
AuthPolicy from accidentally satisfying the customer-identity gate.

The current innovation preflight is clean (`failures=0`, two expected warnings).
The production audit has exactly two intentional failures: the installed MCP
Gateway is still `mcp-gateway.v0.7.1` on the `preview` channel, and no approved
OIDC issuer has been supplied. All live infrastructure, OpenShift edge TLS,
DNS, ingress health, backend isolation, same-port routing, and TokenReview
runtime checks pass. The remaining support and OIDC decisions require platform
or customer authority; Project Matrix must not fabricate either approval.

## Closure Entry — 2026-10-19 — OpenShift-Native Auth Default and Final Live Gate

The live production-profile run now treats OpenShift Kubernetes TokenReview as
the explicit Red Hat-native default authentication mode. The active
`mcp-auth-policy` matches that mechanism and is `Accepted=True` and
`Enforced=True`; production-profile protocol validation passes the complete
sequence: unauthenticated HTTP 401, authenticated `initialize` with session
propagation, `tools/list`, a non-destructive `namespaces_list` `tools/call`,
and direct-backend bypass denial. Gatekeeper also normalizes the MCP
`text/event-stream` response framing, so the validator now behaves as a real
MCP client rather than falsely rejecting successful SSE responses.

The final live lane shape is now precise: innovation preflight is clean with
one expected Technology Preview warning; production preflight has one failure,
the installed MCP Gateway `v0.7.1` `preview` channel. Native OIDC remains an
opt-in customer-identity mode and is mechanism-checked when selected; it is no
longer an unnecessary prerequisite for the Red Hat-native Gateway evaluation
path. The only remaining production gate for that default path is an actual
supported Gateway release/channel or an explicitly approved, time-bounded
exception. Project Matrix cannot manufacture either authority.

## Release and Aramco Reassessment Entry — 2026-10-19 — Upstream Has Advanced Beyond the Live Package

The latest-release audit corrected the project’s version assumption. The live
cluster has OpenShift AI 3.5.0, RHCL operator 1.4.3, and
`mcp-gateway.v0.7.1` from the only available `preview` channel. The RHCL
package catalog exposes 1.4.4 on its `stable-1.4` channel, but the live
subscription remains on stable 1.4.3 and the MCP Gateway package still exposes
only `preview`. The upstream Kuadrant MCP Gateway repository has advanced to
v1.0.2, released 2026-10-16. Upstream v1.0.2 is therefore the latest upstream
engineering reference, not proof of a Red Hat-supported replacement for the
live image.

The two gates must now be described precisely:

1. **Release/support gate:** move to a Red Hat-supported MCP Gateway channel or
   obtain a real, time-bounded exception. An upstream image can be used for an
   isolated engineering lane, but Project Matrix must not silently replace the
   Red Hat-packaged operator image and call that production support.
2. **Documented identity/authorization gate:** the live OpenShift Kubernetes
   TokenReview path is technically proven and useful for an OpenShift-native
   evaluation lane. RHCL’s documented MCP authentication path is JWT/OIDC, and
   its documented per-tool authorization path targets the `mcps` listener. The
   live custom policy currently targets only `mcp`; therefore TokenReview proof
   closes runtime authentication for this cluster but does not yet qualify the
   full RHCL-documented customer identity and `mcps` authorization contract.

## Correction Entry — 2026-10-19 — OIDC 500 Was Pre-TLS-Bootstrap State

The OIDC gate was re-tested after the OpenShift AI Authorino TLS bootstrap
repair rather than relying on the earlier result. A controlled application of
the documented Keycloak JWT `AuthPolicy` produced `Accepted=True` and
`Enforced=True`; the public unauthenticated MCP request returned HTTP 401. The
earlier HTTP 500 therefore belonged to the pre-bootstrap Authorino/Envoy
transport mismatch and is not the current OIDC result. The proven OpenShift
TokenReview policy was restored immediately after the probe.

This narrows the remaining identity work: obtain an approved short-lived OIDC
credential and prove authenticated `initialize`, `tools/list`, and a
non-destructive `tools/call`; then add and validate the separate `mcps`
listener AuthPolicy required for documented per-tool authorization. The 401
compatibility bug itself is closed.

The Saudi Aramco findings are not all equally closed. Same-port listener
topology, the named `mcp`/`mcps` sections, actual `privateHost` Service
discovery, HTTPRoute schema validation, OpenShift Route exposure, Authorino
service-CA TLS bootstrap, and full initialize/tools/list/tools/call validation
are closed on the target and represented in Gatekeeper. Portable ClusterIP plus
`infrastructure.parametersRef` exposure, operator namespace/CSV-copy guidance,
customer TLS-secret discovery for non-Route Gateway TLS, explicit omission of
unneeded backend credentials, and a separate `mcps` authorization policy are
not yet complete as reusable cross-cluster installer behavior. The checklist
now records those as remaining hardening work rather than implying that one
cluster’s successful proof eradicated every upstream/documentation defect.

## Preview Lane Entry — 2026-10-19 — One Authoritative Upstream Preview on the Production-Grade Cluster

The preview policy is now unambiguous. Project Matrix has one and only one
preview implementation: upstream Kuadrant MCP Gateway `v1.0.2`, pinned to
commit `e48ae51cfa52a57f93f334bdadbe8ce58ef5a9f6`. The Red Hat OLM-managed
`mcp-gateway.v0.7.1` remains the production/support compatibility baseline;
it is not treated as a competing preview lane.

The same OpenShift AI cluster remains the validation environment for both
lanes. The upstream preview is isolated by namespace, Gateway, Route, and
release markers so it can exercise the real OpenShift AI, OpenShift Gateway
API, Authorino, and Connectivity Link environment without replacing the live
Red Hat-managed Gateway.

The upstream OpenShift deployment declares RHCL 1.5.0 or newer as a
prerequisite. The live cluster currently reports RHCL `1.4.3` as
`Failed/UnsupportedOperatorGroup` (with a copied `1.4.2` CSV in the operator
scope inventory) and exposes only the Red Hat MCP Gateway `preview` package at
`v0.7.1`. The new preview installer
therefore fails closed before namespace or Helm mutation when RHCL 1.5+ is not
present. This is the correct production-quality behavior: the cluster is
still useful for current production-baseline validation, but the latest
upstream preview cannot honestly be claimed as deployed until its dependency
is available.

The Saudi Aramco findings are now generalized as reusable Gatekeeper contracts:
same-port listeners and named sections; actual private Service discovery;
served HTTPRoute schema validation; explicit Route, LoadBalancer, and
ClusterIP exposure modes; `infrastructure.parametersRef` visibility;
customer TLS Secret discovery; operator namespace/CSV-copy reporting;
credential omission for unauthenticated backends; and a distinct `mcps`
listener AuthPolicy. The OpenShift TokenReview `mcps` policy is implemented as
the native proof lane. Positive OIDC and per-tool authorization remain live
qualification gates.

The OCI chart was verified read-only and is pinned in the installer to digest
`sha256:97be2a4ba4daae5b5a8470074c414a94c02689d3e9c3910eaa098f6044e42eb3`,
so the preview lane cannot silently move underneath the recorded upstream
version.

## RHCL Gate Entry — 2026-10-19 — Platform Prerequisite Implemented and Proven Closed

The RHCL prerequisite is now implemented as a reusable, read-only Gatekeeper
gate at `gatekeeper/rhcl/check-readiness.sh`. The upstream installer invokes this
gate before any namespace, Helm release, Gateway, Route, or operator mutation.
The gate checks the approved OLM catalog, the cluster-wide AllNamespaces RHCL
CSV, and duplicate namespace-scoped subscriptions. A failed gate produces a
non-zero result and the installer explicitly confirms that no preview resource
was changed.

The live result is blocked for two concrete platform-owner actions:

1. The cluster's approved catalog exposes only RHCL `stable`/1.4.3 and
   `stable-1.4`/1.4.4; no RHCL 1.5.0+ candidate is available.
2. `mcp-gateway-system` contains a duplicate RHCL subscription whose CSV is
   `Failed/UnsupportedOperatorGroup`. RHCL is AllNamespaces-only; the healthy
   cluster-wide installation is RHCL 1.4.2 under `openshift-operators`, but it
   does not satisfy the upstream v1.0.2 prerequisite.

The installer was executed with preview confirmation enabled as a negative
test. It stopped at the RHCL gate with exit code 1 and `mcp-gateway-preview`
remained absent. Project Matrix therefore has implemented the next gate without
claiming that the latest upstream preview is deployable yet. The remaining
cluster changes belong to the approved platform OLM/catalog workflow.

## RHCL Remediation Entry — 2026-10-19 — Invalid Namespace Installation Removed

The approved remediation action was executed against the live cluster. The
duplicate Subscription
`mcp-gateway-system/rhcl-operator-stable-redhat-operators-openshift-marketplace`
was removed. Its two failed CSV remnants (`rhcl-operator.v1.4.2` and
`rhcl-operator.v1.4.3`) were also removed from that namespace. The healthy
cluster-wide `openshift-operators/rhcl-operator.v1.4.2` installation was not
modified. OLM recreated the expected copied CSV in `mcp-gateway-system`.

The readiness gate now has a single failure: the healthy Red Hat catalog
publishes RHCL 1.4.x only, not RHCL 1.5.0+. This is no longer an in-cluster
scope or duplicate-installation problem. The upstream preview remains blocked
until the platform/catalog owner makes an approved RHCL 1.5+ OLM path
available. No unsupported CatalogSource or container-image installation was
introduced.

## UI Readiness Entry — 2026-10-19 — Remote Is Buildable, Host E2E Not Yet Qualified (superseded by live acceptance below)

The Project Matrix UI is now analyzable as a real OpenShift AI federated remote,
not merely a mock. The standalone production build succeeds, the host
integration validator passes, the constrained BFF has unit coverage, and the
controller tests and vet pass. The UI exposes the intended single control:
Preview capabilities `OFF|ON`, backed by the fixed Gatekeeper
`LayerDeployment` intent.

At the time of this entry, the live customer click was not yet qualified. The
Dashboard host had not consumed the package in a combined OpenShift AI image,
the BFF/controller images still required immutable promoted release
references, and the executor image was intentionally empty in the deployment
ConfigMap, leaving the controller plan-only. The later acceptance entry below
records the completed live control-plane build, native evaluation images,
status polling, isolated Preview adapter, and end-to-end BFF/controller/Job
execution. Combined Dashboard host registration and canonical image
promotion remain open.

The audit also found a safety-critical integration gap before end-to-end
testing: the Preview intent reached the generic Gatekeeper Job and could have
defaulted to the existing Gateway namespace. That gap was closed before the
live acceptance run: Preview now invokes the isolated upstream installer
contract, targets the preview namespace, and reports asynchronous Job/evidence
status through the same control plane.

## Acceptance Entry — 2026-10-19 — One Package, Two Selectable Lanes Proven Live

The shipping boundary is now explicit and enforced: Project Matrix is one
artifact, one Kustomize installation, one Dashboard/BFF/controller path, and
one Gateway `LayerDeployment`. Production and Innovation are operating lanes
inside that artifact; they are not separate products, installers, or image
sets. Production is the default and uses the Red Hat-managed support boundary.
Innovation is an explicit user selection that targets only the pinned upstream
preview namespace and reports its Technology/Developer Preview boundary.

The live acceptance test was completed against the OpenShift AI validation
cluster. The guarded teardown removed only Project Matrix-owned namespaces,
CRD, RBAC, controller, BFF, and evidence resources. The Red Hat-managed
`mcp-gateway-system/Gateway/mcp-gateway` UID remained
`6716b7ed-3143-48d9-bb0e-e62cf5585bc9`; the separate
`project-matrix-build` evaluation namespace also remained intact. The same
unmodified package then reinstalled successfully after Kubernetes namespace
finalization completed, and both control-plane Deployments became Ready.

The post-reinstall UI path was exercised through the authenticated BFF:

- unauthenticated GET: HTTP 401 with `Unauthenticated`;
- authenticated empty-state GET: HTTP 200 with no LayerDeployment;
- Production click: HTTP 201, followed by the intended fail-closed
  `Degraded` result because the installed MCP Gateway is not a supported
  Production dependency;
- Innovation click on the same LayerDeployment: HTTP 200, followed by the
  isolated Preview `Degraded` result because RHCL 1.5+ is not available;
- final status explicitly reported `mode=Preview`, the Innovation support
  boundary, and the shared evidence ConfigMap reference.

The Preview job stopped before mutation and reported that no namespace, Helm
release, operator, or Gateway resource was changed. The current job uses
`backoffLimit: 0`; historical failed Pods from the pre-fix Job replacement
test were removed by teardown. This closes the live control-plane,
teardown/reinstall, mode-switch, and fail-closed diagnostics gates. It does
not claim the remaining external release gates: canonical Quay promotion,
combined OpenShift AI Dashboard host registration, RHCL 1.5+ availability,
or a supported MCP Gateway release/exception.

## Correctness Entry — 2026-10-19 — Foreground Cleanup on Lane Replacement

The live lane-switch test exposed one cleanup defect: replacing a terminal
Production Job with the Innovation Job used background deletion and left its
failed Pod orphaned. The controller now requests Kubernetes foreground
propagation when replacing an immutable Job, so the owned Pod is removed before
the replacement is created. Go tests and vet pass, the controller was rebuilt
natively by OpenShift, and the new immutable evaluation digest is recorded in
`deploy/IMAGE_RELEASE_LOCK.md`. This keeps one-click retry and lane switching
bounded and makes Job/Pod evidence unambiguous.

The teardown acceptance also exposed a timing edge in the operator-facing
script: namespace deletion is asynchronous. `deploy/teardown.sh` now waits up
to 120 seconds for the two Project Matrix-owned namespaces to finalize before
returning, so a customer can run teardown followed immediately by reinstall
without a manual sleep or a race with namespace termination.

The hardened script was rerun live after this change. It waited for
finalization, preserved the same managed Gateway UID, and the unchanged
package reinstalled with the controller and two dashboard BFF replicas Ready.
The cluster was left in the clean post-install state with no LayerDeployment,
ready for the next user-driven one-click test.

## Execution Decision — 2026-10-20 — Production-Shaped Path First

The implementation will now sequence the remaining work by executable value,
not by external release dependency order. The live OpenShift AI instance is
the runtime and validation target. The immediate objective is to finish the
full **production-shaped** Gateway experience on the currently installed
Red-Hat-managed baseline: Dashboard host registration, combined evaluation
image, one-click Production execution, authenticated BFF/controller flow,
teardown/reinstall, status/evidence, and upgrade-safe behavior.

This is deliberately precise about the support boundary. The current Gateway
is still Technology Preview, so the production-shaped track can be functionally
complete without claiming supported Red Hat Production status. The native
OpenShift TokenReview profile is the evaluation identity path; the
RHCL-documented OIDC and `mcps` authorization path remains a separate release
qualification gate.

The Innovation lane remains in the same shipped artifact and remains the sole
pinned upstream preview path. It is not being removed or split into a second
product. Its live activation waits for the approved RHCL 1.5+ prerequisite,
but that prerequisite no longer blocks Dashboard, control-plane, reinstall,
and production-shaped functional testing.

Likewise, canonical Quay promotion is a release packaging gate rather than a
reason to stop testing with the immutable evaluation images already built and
validated in the cluster-local registry. Once the host-integrated evaluation
image is proven, the exact immutable artifacts will be promoted without
changing the one-package/two-lane contract.

## Release Entry — 2026-10-20 — Cluster-Native Quay Promotion

The local Podman VM was unavailable, so promotion was performed directly from
the live OpenShift integrated registry using `oc image mirror`. The current
OpenShift session supplied the source-registry credential, and the existing
Quay credential was used without being written to the repository or exposed in
evidence.

The following live validation digests were copied to the canonical
`quay.io/aicatalyst` repositories under the `20261020-gateway-layer` alias and
verified at Quay with the same immutable digests:

- controller: `8754427d…`
- Gatekeeper: `4cd336e4…`
- Dashboard BFF: `8e231e6b…`

This closes canonical promotion for the current control-plane images. It does
not close the separate combined OpenShift AI Dashboard host image, which must
still be built from the compatible Dashboard workspace after the Project Matrix
package registration is consumed by the host build.

## Dashboard Host Entry — 2026-10-20 — Native Build Qualification

The Project Matrix package was consumed by the compatible OpenShift AI Dashboard
workspace and the targeted host build passed locally. A clean native build was
then submitted to the live cluster in the isolated `project-matrix-build`
namespace, without touching the running Dashboard deployment.

The first clean host build proved that the complete host graph discovers
`@odh-dashboard/project-matrix` alongside the existing OpenShift AI extensions,
including OpenClaw. It exposed host-workspace dependency defects rather than
Project Matrix defects:

1. Hoisted Perses plugins could not resolve `echarts` and
   `@tanstack/react-query` from the host root.
2. The OpenShift dynamic-plugin SDK utilities could not resolve their declared
   `@openshift/dynamic-plugin-sdk-extensions` peer.

The compatible workspace now records the minimal root build dependencies and
an explicit `legacy-peer-deps` setting in `.npmrc`, with the lockfile updated.
The next native build reduced the failure to the single missing SDK extension;
that exact compatible `1.4.1` package is now also recorded. The next resubmit
was blocked only by expiration of the live `oc` session, not by a Project Matrix
build error. The evaluation BuildConfig remains ready at
`deploy/dashboard-host-buildconfig.yaml`.

No production Dashboard deployment was modified while the combined host image
was being qualified.

The refreshed live login was supplied and native build `project-matrix-dashboard-host-5`
completed successfully. Its combined host image includes the full existing
OpenShift AI extension graph plus Project Matrix and is available in the
cluster-local registry at digest `76c1eab9…`. The build emitted existing
dependency-audit findings (147 reported by npm audit, including 10 critical)
and normal webpack/Sass/browser-data warnings, but no compilation errors. The
audit findings belong to the compatible Dashboard host dependency tree and are
now a separate security-triage gate before claiming a production-grade host
release; they are not Project Matrix runtime findings.

The first secure promotion attempt was rejected because the cluster registry
Route certificate is expired. A port-forward retry avoided that edge
certificate but timed out during the large upload. A serialized direct retry
then reached Quay, accepted the remaining layers after one transient HTTP 503,
and published the combined host manifest. Quay verification returned the same
immutable digest `76c1eab9…`.

The image-release gate is now closed for the current control-plane and
Dashboard host artifacts. The next UI action is a controlled evaluation
deployment of this host image; the existing production Dashboard remains
untouched until that deployment path is explicitly reviewed.

## Dashboard Evaluation Entry — 2026-10-20 — Isolated Host Validation

The combined OpenShift AI Dashboard host image was deployed to the live
cluster as an isolated evaluation copy. The operator-managed
`redhat-ods-applications/deployment/rhods-dashboard`, its production Service,
and its production Routes were not modified.

The evaluation copy uses the immutable cluster-local host image digest
`76c1eab9…`, reuses the existing Red Hat Dashboard sidecars, TLS material,
federation configuration, probes, and service account, and has a dedicated
Deployment, Service, and re-encrypted Route:

```text
redhat-ods-applications/project-matrix-dashboard-eval
https://project-matrix-dashboard-eval-redhat-ods-applications.apps.ocp-gb.ibm.redhataicatalyst.com
```

The existing `rhods-dashboard` service account received only
`system:image-puller` access in `project-matrix-build`; no Quay credential was
copied into the platform namespace. The rollout reached `3/3` ready
containers with zero restarts. The direct evaluation Route correctly returns
`401` without credentials and `200` for `/` and `/api/health` with the current
OpenShift identity token. The normal `rh-ai` entrypoint continues to use the
platform OAuth front door and returns the expected OAuth redirect.

This closes the live combined-host deployment and health gate for evaluation.
It does not yet claim a production Dashboard host release: the host dependency
audit remains a separate security-triage gate, and the evaluation Route is an
explicit opt-in validation surface rather than a replacement for the
operator-managed Dashboard entrypoint.

The deployment procedure is now captured in
`deploy/deploy-dashboard-host-evaluation.sh`. A repeat run was validated on
the live cluster, including safe Route replacement and rollout completion. A
Route CA-encoding defect found during that test was corrected; the final
re-encrypted Route is admitted and returns `200` with the current OpenShift
identity and `401` without it.

## Dashboard OAuth Entry — 2026-10-20 — Browser Evaluation Gate

The isolated host now has a dedicated Red Hat `kube-auth-proxy` front door at:

```text
https://project-matrix-dashboard-eval.apps.ocp-gb.ibm.redhataicatalyst.com
```

This path uses the same pinned Red Hat auth-proxy image pattern as the live
OpenShift AI Gateway, but has its own OAuthClient, credentials, cookie name,
Service, Deployment, and re-encrypted Route. The production `data-science`
OAuthClient, `GatewayConfig`, `rh-ai` Route, and operator-managed Dashboard
were not changed.

The unauthenticated browser path returns the expected OpenShift OAuth `302`
with the dedicated client and callback URI. OpenShift TokenReview validation
of the current identity returns `200` for both `/` and `/api/health`. The host
listener is reachable only through the dedicated auth proxy or the existing
Dashboard proxy path; the internal evaluation upstream is constrained by a
namespace/pod-scoped NetworkPolicy.

The repeatable procedure is
`deploy/deploy-dashboard-host-auth-evaluation.sh`. The browser/OAuth gate for
the evaluation copy is closed. This does not yet make the combined host a
supported production Dashboard release: the host dependency audit remains a
separate acceptance gate.

## OAuth Callback Diagnosis — 2026-10-20 — Cluster Certificate Boundary

The first interactive browser callback reached the dedicated OAuthClient but
returned HTTP 500 during authorization-code redemption. Live evidence showed
the external OpenShift OAuth Route certificate had expired at
`2026-10-20T16:45:40Z`. The evaluation proxy was corrected to redeem against
the in-cluster `oauth-openshift.openshift-authentication.svc` endpoint using
the namespace `openshift-service-ca.crt`, retaining TLS verification.

After the correction, the isolated auth proxy remained `2/2` ready, returned
the expected unauthenticated OAuth redirect, and continued to return `200`
for token-authenticated Dashboard health. The platform owner subsequently
repaired the external wildcard certificate, closing that certificate gate.

## Project Matrix Convention and Live Demo Baseline — 2026-10-21

The internal naming convention is now **Project Matrix**. Official Red Hat AI:
Agentic Strategy layer names remain primary, with Matrix codenames as the
secondary journey language:

```text
Infrastructure              The Source
vLLM (Core)                 The One
llm-d                       The Architect
OGX                         The Keymaker
Gateway                     The Gatekeeper
Secure Agent Onboarding     Trinity
AgentOps                    The Oracle
BYOA                        Zion
```

The OpenShift AI Dashboard experience is **The Construct**. Production is
**The Red Path** and Innovation is **The Blue Path**. These are presentation
terms only; the API continues to use the explicit `Production` and `Preview`
values and every support boundary remains visible.

The live target cluster is ready for the current production-shaped demo:
OpenShift 4.21.8, the OpenShift AI DataScienceCluster, and all ClusterOperators
passed the read-only baseline. The Project Matrix controller and Dashboard BFF
are ready, and the isolated combined Dashboard host plus dedicated OAuth proxy
are both ready. Browser entry returns the OpenShift OAuth redirect, while the
token-authenticated Dashboard health endpoint returns `200`.

The current live release gates are explicit: the installed MCP Gateway is
Red Hat OLM `0.7.1` on `preview`, RHCL is `1.4.2`, and the catalog has no RHCL
`1.5.0+`; therefore the isolated upstream Innovation path remains fail-closed.
The production support boundary and host dependency-audit findings remain
separate acceptance gates.

## Project Matrix Live Migration — 2026-10-21

The source migration from the former internal convention is complete. The
project now lives at `/Users/geraldtrotman/Virtualenvs/project-matrix`, and a
legacy-name scan is clean across source content and paths. The canonical
Matrix identifiers are now used for the API group, runtime namespace,
Dashboard package/module, Gatekeeper executor, manifests, release lock, and
documentation.

The renamed controller, Dashboard BFF, and Gatekeeper images were built on the
target OpenShift cluster and pinned by immutable digests. The compatible
OpenShift AI Dashboard workspace package was migrated to `packages/project-matrix`
and its workspace lockfile was regenerated. Controller tests, profile catalog
validation, frontend type-check/build, host federation validation, shell syntax,
and Kustomize rendering all pass.

The Matrix CRD and runtime were then installed in the isolated `matrix-system`
namespace. The Red Hat-managed MCP Gateway was not changed. The BFF one-click
path created `matrix-system/gatekeeper` with `Gateway / Gatekeeper / Production`.
The real Gatekeeper execution ran and correctly failed closed in `Degraded`
because the live Gateway extension/service exposure, effective backend
isolation, production support boundary, and endpoint-validation prerequisites
are not all satisfied. No installation or evaluation mutation occurred after
the failed preflight. This is the desired safety behavior and is now live
demo evidence rather than a mocked success.

## Lean Release and Browser Demonstration — 2026-10-21

The end-user experience was made an explicit release criterion: customers pull
promoted immutable images and apply the declarative package; they do not upload
the Dashboard workspace, run `oc start-build`, install Node dependencies, or
compile Project Matrix locally. A maintainer-only build helper now excludes
the vendored upstream checkout, evidence archive, VCS data, and local package
caches from binary release uploads.

The combined Matrix Dashboard host was rebuilt successfully using that bounded
context and deployed only as the isolated evaluation copy. Its dedicated Red
Hat `kube-auth-proxy` front door and OAuthClient are ready, and the external
route returns the expected OpenShift OAuth redirect. The browser entry point
is now:

`https://project-matrix-dashboard-eval.apps.ocp-gb.ibm.redhataicatalyst.com`

The runtime images were measured on the live ImageStreams: controller 62.8 MB,
Dashboard BFF 52.8 MB, combined host 274.4 MB, and Gatekeeper 124.6 MB. The
Gatekeeper image was reduced from 472.4 MB by moving from the full Python UBI
runtime to `ubi-minimal` with only the required runtime packages. The optional
customer-workflow helpers remain available, while Aramco remains provenance
and validation context rather than a product-specific scope.

The new Gatekeeper digest was applied to the live Matrix controller and the
controller rolled out successfully. The host dependency audit still reports
28 runtime findings, including four critical findings; this remains an open
security acceptance gate and prevents a production-grade Dashboard host claim.

## Native Dashboard Ownership Boundary — 2026-10-21

The requested top-order user journey was tested against the actual native
OpenShift AI landing page, `https://rh-ai.apps.ocp-gb.ibm.redhataicatalyst.com/`.
The compatible Dashboard host now contains a first-party
`ProjectMatrixHomeCard` rendered from the native `Home` page. The card opens
The Construct at `/project-matrix`; the federated Project Matrix package owns
the layer journey, Production/Preview control, status polling, and BFF action.

The host workspace type-check and targeted lint passed. A full native
`BUILD_MODE=RHOAI` build completed on the live cluster and produced the
cluster-local immutable host image
`sha256:6b8060a28237430a8b3a88e39ef9e3ed1e7791f8a83dd873b10519d2df8ee79a`.

The OpenShift AI Dashboard CR has no custom image field. A controlled attempt
to point the operator and `rhods-dashboard` Deployment at the Matrix host was
immediately reconciled back to the Red Hat image. This is important evidence:
the customer installer must not patch the operator-managed Dashboard out of
band. The tile is implemented in host source, but it will become visible on
the native landing page only through the normal Dashboard release/packaging
path. Until then, the isolated Matrix host remains the browser demonstration
surface and must not be presented as the native production Dashboard.

## Client and Development Handoff Bar — 2026-10-21

The objective is explicit and persistent: Project Matrix must produce one
artifact that can be demonstrated to a client, handed to a client for use,
and handed to product development as the bounded implementation for official
OpenShift AI productization. A client demonstration is not allowed to depend
on a private maintainer workflow or a divergent demo-only code path.

The live Dashboard integration reached its first end-to-end acceptance point.
The isolated evaluation host uses the combined Dashboard image, the Red Hat
`odh-kube-auth-proxy` OAuth front door, the Matrix federated remote, and the
Matrix BFF/controller on the supplied OpenShift AI cluster. Authenticated
smoke tests pass for the host shell, `/_mf/projectMatrix/remoteEntry.js`, and
the Gatekeeper API. Unauthenticated access redirects to OpenShift OAuth.

The same authenticated API contract exercised the Innovation switch. The BFF
accepted the constrained Preview intent, the controller selected the upstream
preview executor, and execution stopped before mutation because the live RHCL
readiness gate is blocked: `rhcl-operator` is absent and the pinned upstream
preview requires RHCL 1.5.0 or newer. The default Production lane was
restored and remains fail-closed with evidence for its nine unmet preflight
gates. This proves that the UI action, identity boundary, lane selection,
asynchronous status path, and support-boundary behavior use the same shipped
control plane.

The evaluation URL is a client/demo surface, not a replacement for the
operator-managed native Dashboard. The native `rh-ai` landing-page tile is
implemented in the compatible Dashboard host source and combined host image,
but can become visible in the native production UI only through the normal
OpenShift AI Dashboard host release/packaging path. Product development now
has a concrete host integration contract and a live-tested reference to
productize; the next acceptance step is browser validation of the evaluation
surface, followed by the clean GitHub milestone push.

## AI Stack user experience refinement — 2026-10-21

The customer-facing destination is now named **AI Stack**, with the page
presented as **Red Hat AI Stack**. “Red Hat AI: Agentic Strategy” remains the
architectural source vocabulary in the journal and layer mapping, but it is no
longer the primary navigation or landing-page label.

The Gateway horizontal now has one primary action whose verb reflects the
actual lifecycle: `Install Gateway`, `Installing ...`, `Gateway installed`, or
`Retry Gateway`. The selected layer remains visible as `Gateway layer · The
Gatekeeper`, with a concise description of the MCP Gateway, MaaS Gateway,
identity policy, exposure, and conformance work included in that layer.

The LayerDeployment API now exposes `status.currentStep`. The controller
publishes Gateway-specific steps such as checking Red Hat-supported
prerequisites, installing and validating the isolated upstream Gateway, ready,
or blocked by a dependency/validation gate. This status is consumed by the
Dashboard rather than invented solely in the browser, preserving the same
contract for every future horizontal layer.

## AI Stack landing page and installer flow — 2026-10-21

The next UX correction was important: the destination cannot look like a
Gateway-only application when the product objective is a family of independent
horizontal installers. The Matrix page is now a true **Red Hat AI Stack**
landing page. It presents the layers in their architectural order:

```text
BYOA → Secure Agent Onboarding → Gateway → OGX → llm-d → vLLM (Core) → AgentOps → Infrastructure
```

Each layer has its official Red Hat AI: Agentic Strategy name, its Matrix
codename, a concise description, and an honest availability state. Gatekeeper
is the only enabled installer today; the remaining rows are visible as
“Coming soon” rather than being hidden or represented as fake controls. This
establishes the reusable product contract for every future layer: one layer,
one guided install action, one truthful status stream, and one evidence path.

The OpenClaw-on-ODH experience provided the interaction model: a dedicated
entry point, one obvious deployment action, live lifecycle language, and a
plain result for success or failure. Matrix now follows that model while
retaining its Kubernetes controller and authenticated BFF. The Innovation
switch no longer submits an operation merely because it was toggled; it selects
the lane and the user explicitly presses the single install action. Production
remains the default.

The evaluation host was rebuilt from the bounded ODH Dashboard context and
rolled to the live isolated route with immutable host digest
`sha256:a5d04572679cbf1c2bebf8373c85f000fcc15d2e0a50deffcc63121ea170cddc`.
The operator-managed native Dashboard remains untouched. Browser acceptance of
the stack landing page is the final gate before freezing this UI milestone and
promoting it to GitHub; only then does the effort return to the remaining
production, innovation, RHCL, authentication, support, and release gaps.

## Interactive stack-map direction — 2026-10-21

The static stack catalog was not sufficient for the intended OpenClaw-like
installer experience. The stack map is now a code-native interactive component
that preserves the reference drawing’s visual language: colored horizontal
bands, slightly irregular paper-like edges, black hand-drawn-style outlines,
red selection treatment, and a lifted shadow on hover or keyboard focus.

Every layer band is a real accessible button. Selecting a band changes the
installer panel below it. Gatekeeper opens the live Gateway installer; future
layers open an honest “Coming soon” panel until their adapter and validation
contract exist. This keeps the visual metaphor aligned with the actual shipped
capability instead of turning the illustration into decorative artwork.

The final interaction target is therefore: enter **Red Hat AI Stack**, hover or
select a layer in the map, and receive that layer’s guided installer and
truthful lifecycle state in the same page. The live host promotion is pending
because the current `oc` session expired during the rebuild; source validation
passes and the next cluster action is to rebuild the isolated host with this
interactive remote, then repeat browser acceptance before the GitHub push.

## Interactive stack-map promotion — 2026-10-21

The cluster session was restored and the combined isolated Dashboard host was
rebuilt successfully. The interactive stack map is now live at:

`https://project-matrix-dashboard-eval.apps.ocp-gb.ibm.redhataicatalyst.com/`

The OAuth front door returns the expected unauthenticated redirect, while
authenticated requests return HTTP 200 for both the host shell and
`/_mf/projectMatrix/remoteEntry.js`. The evaluation host is running immutable
digest
`sha256:184bf7a80c1ae2e92cf82beb59da45620616cd9e540c547f5e93ef3aa35fea0d`.

This closes the implementation gate for the visual installer entry point. The
remaining acceptance action is human browser inspection: hover each layer,
select future layers, select Gatekeeper, verify the Production default, toggle
Innovation without submission, and confirm the single install action reports
the real current step. After that acceptance, freeze and push the milestone to
GitHub before returning to the remaining production-grade gaps.

## Exact supplied artwork with minimal installer rail — 2026-10-21

The code-native approximation was rejected because the product requirement is
the supplied hand-drawn marker artwork itself. The Matrix UI now uses the
exact clean platform-stack crop as its visual asset. The layer controls are
transparent accessible hotspots positioned over the original bands, so hover
lift, focus, selection, and status do not redraw or reinterpret the marker
artwork.

The installer surface below the artwork now follows the OpenClaw-on-ODH
interaction model: one selected layer, one clear Gateway action, live
controller-owned status, Production selected by default, Innovation selected
explicitly without submitting, and expandable validation evidence. Future
layers remain visible in the stack and honestly report “Coming soon.”

The optimized artwork is served as a 531 KiB JPEG from the dashboard's static
image path. This preserves the supplied look while avoiding the unsupported
asset-module path in the shared OpenShift AI host webpack configuration.

The combined host was rebuilt natively and promoted to the protected live
evaluation route:

https://project-matrix-dashboard-eval.apps.ocp-gb.ibm.redhataicatalyst.com/

Current immutable host digest:

sha256:8d44afe0da81929d7c00dafb425e44da0ad4eb309ebfbb10ff23fe8a0bc4318c

Automated checks pass: unauthenticated host 302, authenticated host 200,
authenticated /_mf/projectMatrix/remoteEntry.js 200, and authenticated
artwork URL 200. Human browser inspection is now the immediate gate before
the GitHub milestone push.

## Correction: from-scratch stack artwork and workflow state — 2026-10-22

The prior implementation used the supplied screenshot as a raster image with
transparent interaction targets. That was incorrect and is superseded.

The current implementation renders the platform stack from scratch as an
interactive SVG component. Each layer is a real SVG interaction target with
its own marker-style band, irregular outline, handwritten label, icons,
arrows, hover lift, keyboard focus, and selected state. No supplied screenshot
is shipped or displayed by the current implementation.

The Gateway experience now follows the actual OpenClaw UX lesson:

1. Before the action, the user sees exactly what the Gateway layer installs:
   MCP Gateway, MaaS Gateway, identity/authenticated exposure, and validation
   evidence.
2. The user selects Production or Innovation and clicks one action.
3. The preview changes into live installation status showing the actual
   controller-owned step, phase, and lane until the operation completes or
   stops at a dependency/support gate.

The corrected host is live at the protected evaluation route:

https://project-matrix-dashboard-eval.apps.ocp-gb.ibm.redhataicatalyst.com/

Current host digest:

sha256:618983d55689f25dfb4469823e61d08a8752586476b7c8446876703118637f0c

The standalone frontend type-check and production build pass. The host
rollout and OAuth/module smoke checks pass. Browser acceptance is now the
remaining UI gate before the GitHub milestone push.

## Artwork cleanup — 2026-10-22

The first live SVG render preserved the intended band colors in source, but
the host browser showed black bands because the marker-wobble SVG filter was
not rendering safely in that environment. The final cleanup removes that
filter, removes the opaque white SVG canvas, and removes the surrounding
decorative arrows. The bands remain code-native SVG with their marker-style
outlines, typography, icons, hover lift, and interactive layer selection.

The corrected host was rebuilt and rolled out with immutable digest
`sha256:a4c7b72bb84e063759f8c2f83cc98181679155ecb6ca004d4a3781d6291722c3`.
The protected route and running pod are healthy; browser inspection is the
remaining acceptance gate.

## Foreground-first selection and concept motion — 2026-10-22

The interaction model was tightened around the OpenClaw-like workflow and the
stack's role as a landing page for multiple horizontal installers:

- Initial render keeps every layer in the foreground, with no arbitrary
  preselected layer dimming the stack.
- Clicking or keyboard-selecting a layer creates the focus state. The chosen
  band lifts above the stack and the unclicked layers recede into the
  background, preserving the layer's visual position and meaning.
- The selected band is the primary lift. Its constituent concepts then lift
  independently through dedicated SVG wrapper groups with a short stagger, so
  the motion is visible for icons, labels, and capability pills rather than
  relying on a transform composition that can be overridden by SVG children.
- Hover and keyboard focus retain the same layer-level and concept-level
  acknowledgement, while reduced-motion preferences disable the transitions.

The host was rebuilt and promoted to the live evaluation deployment with
immutable digest
`sha256:613521718598be5f145d3f769cac1bb829ce7eade262312f6dd902406ff70a5d`.
The protected route returns OAuth 302, the direct route returns 401, and the
deployed pod reports all three containers ready. Human browser acceptance is
the remaining UI gate before the GitHub milestone push.

## Upstream-first contribution pivot — 2026-10-22

The implementation target is now the public Open Data Hub Dashboard upstream
repository. The live Red Hat OpenShift AI evaluation host remains useful as a
demo snapshot, but it is no longer the source of truth for feature development.

The supplied contribution workflow establishes the following order:

1. Create or associate an upstream issue and satisfy the repository Definition
   of Ready, including acceptance tests, dependencies, UX approval, API/CRD
   review, architecture review, ownership, and stakeholder estimates.
2. Branch from the refreshed `opendatahub-io/odh-dashboard` `upstream/main`.
3. Develop and validate the Project Matrix extension in that upstream-based
   worktree using the documented `pnpm` development, test, lint, and local
   dashboard workflows.
4. Push the feature branch to the fork and open a PR against
   `opendatahub-io/odh-dashboard:main`; use the PR image and CI for review.
5. Only after upstream merge, backport the resulting commit to the target
   downstream RHOAI branch and run downstream/Konflux gates.

The upstream remote was refreshed to commit
`e072d058e6c4dbb1889c99637be71d252de5fbe7`, and a clean worktree/branch named
`project-matrix-upstream` was created from that commit at
`/Users/geraldtrotman/Virtualenvs/odh-dashboard-upstream`. The prior fork
worktree and live evaluation release are preserved as a separate snapshot.

No further downstream-only feature work will be treated as the implementation
of record until the upstream issue and Definition of Ready gates are satisfied.

The initiative created for this program is [AIPCC-33612|https://redhat.atlassian.net/browse/AIPCC-33612],
parented under [AIPCC-5516|https://redhat.atlassian.net/browse/AIPCC-5516]. It
uses [AIPCC-30779|https://redhat.atlassian.net/browse/AIPCC-30779] as the
initiative template while broadening the scope from a Saudi Aramco demo to the
upstream-first Red Hat AI Stack layer-installer program. Gateway is the first
deliverable; vertical/use-case installers remain follow-on work.

## Jira initiative refinement — 2026-10-24

[AIPCC-33612|https://redhat.atlassian.net/browse/AIPCC-33612] was reviewed
against the journal's detailed architecture, Aramco operational-burden,
Dashboard UX, Production/Innovation, support-gate, and upstream-contribution
entries. Its description was expanded to carry the actual implementation
contract rather than a generic project summary:

* the eight-layer Red Hat AI Stack/Project Matrix mapping and
  horizontal-before-vertical sequencing;
* Gatekeeper's Gateway-first scope and the full Aramco-derived listener,
  routing, TLS, service-discovery, CRD, operator-scope, credential, isolation,
  authentication, and MCP protocol acceptance contract;
* Production-default and explicit Innovation-lane behavior, including the
  no-upgrade boundary and fail-closed support claims;
* Dashboard visual/workflow acceptance, security and platform boundaries;
* upstream Open Data Hub contribution order, downstream backport sequencing,
  Definition of Ready, Definition of Done, and planned child workstreams.

A Jira comment records this refinement. The initiative remains in New status
until stakeholders complete the Definition of Ready; no downstream evaluation
deployment is being treated as upstream implementation evidence.

## Jira template normalization — 2026-10-24

The prior expanded Jira description was intentionally normalized after review.
[AIPCC-33612|https://redhat.atlassian.net/browse/AIPCC-33612] now follows the
same concise initiative template as [AIPCC-30779|https://redhat.atlassian.net/browse/AIPCC-30779]:
Story, Description, Demo flow, Scope, Out of scope, Why now, Definition of
Ready, Definition of Done, Estimation and Due Date, and Scope Guidance.

Detailed listener, authentication, Aramco, and implementation evidence remains
in this journal and belongs in child implementation issues and acceptance
artifacts rather than the initiative summary.

## Jira authoring procedure recovered — 2026-10-24

The prior AIPCC-30779 authoring trail was reviewed and is now the standing Jira
procedure for Project Matrix.

* Use AIPCC-30779 as the immutable editorial and structural template.
* Keep the exact native Jira sequence: Story, Description, Demo flow, Scope,
  Out of scope, Why now, Definition of Ready, Definition of Done, Estimation
  and Due Date, and Scope Guidance.
* Preserve the exact terse style: bold inline labels in Story, bullets for
  enumerated work, and short concrete statements. Only the initiative-specific
  content changes.
* Author through the configured Atlassian path and verify the saved Jira
  document as native ADF nodes. Literal `h2.`, Markdown, or other markup shown
  as text is a failed result.
* Before declaring completion, compare the target issue's node sequence and
  headings with AIPCC-30779 and visually confirm the rendered issue.

AIPCC-33612 was repaired using this procedure. Jira API verification confirms
that its native document node sequence and heading sequence now match
AIPCC-30779 exactly; only its initiative content differs.

## Product alignment — RHAISTRAT-2791 — 2026-10-24

Project Matrix aligns with [RHAISTRAT-2791|https://redhat.atlassian.net/browse/RHAISTRAT-2791],
“One-click install of the MCP server for Red Hat OpenShift with its gateway and
guardrails from the AI Hub.” The feature sits under
[RHAISTRAT-1339|https://redhat.atlassian.net/browse/RHAISTRAT-1339], “AI Hub AI
Asset Delivery for Agentic Solutions.”

RHAISTRAT-2791 is the product-alignment anchor for the Gateway horizontal. Its
strategy calls for an `odh-dashboard` guided install wizard that detects
prerequisites, validates RHCL and the MCP Lifecycle Operator module, performs
RBAC preflight, configures or reuses a compatible gateway, provisions mandatory
guardrails, creates the `MCPServer` resource, verifies the running server, and
supports uninstall. It explicitly keeps external operator installation and
upgrade outside the Dashboard responsibility.

Project Matrix broadens this into the Red Hat AI Stack's layer-centric installer
pattern. Gateway remains the first horizontal deliverable, while RHAISTRAT-2791
provides the concrete AI Hub/MCP Gateway product path and its guardrail,
dependency, verification, and lifecycle expectations.

## AI Hub product-integration pivot — 2026-10-24

The Project Matrix implementation will live in AI Hub. RHAISTRAT-2791 is the
product UX and workflow reference, including its native AI Hub surface, visual
language, guided-install flow, prerequisite gates, live progress, verification,
and lifecycle handling.

The custom Project Matrix landing page and hand-drawn stack artwork remain
historical evaluation artifacts only. They are not the target product UI and
must not be carried forward as a competing surface. The Red Hat AI Stack layer
model, Production/Innovation lane behavior, and Gateway-first sequencing remain
valid as the content and orchestration model behind the AI Hub experience.

The next implementation target is to extend the existing AI Hub experience in
the upstream `odh-dashboard`, using RHAISTRAT-2791's UI/aesthetic and guided
workflow as the baseline. Subsequent Project Matrix layers should appear as
AI Hub capabilities within that same product surface.

## Upstream AI Hub installer slice — 2026-10-24

The clean `odh-dashboard` upstream worktree now has the first implementation
slice for the AI Hub MCP catalog path. The existing catalog detail action is
being changed from a generic deployment modal to an explicit “Install MCP
server” workflow.

The slice reuses the upstream MCP catalog, MCP Lifecycle availability check,
gateway readiness API, catalog-to-`MCPServer` conversion, deployment creation
API, and project deployment polling. Its flow is prerequisite review, compact
resource review, installation submission, and live status from the resulting
deployment conditions. It does not use simulated timers or the retired custom
Project Matrix UI.

This is an upstream UI/integration slice, not completion of RHAISTRAT-2791. RHCL
operator discovery, SubjectAccessReview preflight, guardrail policy
provisioning, authenticated MCP initialize/tools/list/call verification, and
uninstall remain explicit gates. The implementation must not describe those
gates as complete until their real APIs and cluster conditions are wired and
tested.

## Upstream development against the live RHOAI environment — 2026-10-24

The governing development process for Project Matrix is now upstream-first and
live-cluster validated. The implementation source of truth is the clean
`opendatahub-io/odh-dashboard` worktree and its upstream pull request; the
provided RHOAI cluster is the integration and demonstration environment. A
separate local Kubernetes environment is not required for the primary test
loop.

The official upstream development workflow has three distinct mechanisms:

* `?devFeatureFlags` is a browser-session feature-flag switch. It is useful for
  exposing a gated UI to one tester, but it does not deploy new source or
  replace a container image.
* `DEPLOYMENT_MODE=standalone` controls how a Dashboard module is built and
  served during development. It is not a live-cluster image override.
* The upstream Dashboard Module Controller can run from the source worktree
  against the current kubeconfig. Its `RELATED_IMAGE_*` environment variables
  override the images rendered into the managed Dashboard resources. For the
  current Project Matrix slice, the relevant override is
  `RELATED_IMAGE_ODH_MOD_ARCH_MODEL_REGISTRY_IMAGE`, pointing to the validated
  pull-request image.

The official references are `docs/dev-setup.md` for the development server,
session feature flags, cluster access, and image builds;
`docs/dashboard-operator.md` for running the controller against a cluster and
using `RELATED_IMAGE_*` overrides; and `docs/module-federation.md` for the
host/remote federation and service-proxy contract.

The live cluster was inspected and establishes the required control boundary:
`Dashboard/default-dashboard` is Managed and owned by
`DataScienceCluster/default-dsc`; the production `dashboard-operator` runs in
`redhat-ods-applications` and currently supplies the Red Hat model-registry
image through its related-image environment. Direct Deployment or ConfigMap
patches are therefore not a development mechanism: the active operator
reconciles them back to the managed state.

The repeatable Project Matrix live-test loop is consequently:

1. Validate the source, tests, PR image, and current cluster health.
2. Establish an explicit, reversible Dashboard-controller handoff.
3. Run the upstream controller from the source worktree with the selected
   `RELATED_IMAGE_*` override while preserving the production host image.
4. Validate the real AI Hub flow against the live cluster.
5. Stop the development controller, restore managed RHOAI reconciliation, and
   verify Dashboard health and image restoration.

The Production/Innovation distinction remains a product behavior, not a
second shipped implementation: Production is the default and must fail closed
when support gates are not satisfied; Innovation is an explicit evaluation
lane in the same upstream workflow. A development image may be used only for
the Innovation validation path and must never be represented as a supported
Production release.

Because controller handoff can affect the shared AI Hub Dashboard, it is a
deliberate controlled mutation. The standing rule is to perform it when the
user has explicitly requested the live-cluster development loop, but to first
capture the current controller, image, Dashboard condition, and rollback state
and to restore managed reconciliation before declaring the test complete. No
additional cluster token or registry credential is required for this workflow;
the remaining prerequisite is only the reversible ownership handoff.

The pre-handoff snapshot was captured on 2026-10-24. The live baseline is
healthy: `Dashboard/default-dashboard` is `Ready=True`,
`ProvisioningSucceeded=True`, `Degraded=False`, and
`DeploymentsAvailable=True`. `DataScienceCluster/default-dsc` has
`spec.components.dashboard.managementState: Managed`; it owns both the
Dashboard resource and the `dashboard-operator` Deployment in
`redhat-ods-applications`. The managed controller is the RHOAI 3.5.0
Dashboard operator, with the production host and model-registry image digests
currently supplied through its related-image environment. These are the
rollback anchors for the first live upstream test.

## Gateway-layer component contract and demo handoff — 2026-11-06

The Gateway horizontal is now being advanced as a layer-wide installation, not
as an MCP-only click. The next component is **MaaS Gateway**, and its state is
represented as an explicit validation gate until the governed model-response
path has been exercised. The installer must not call the whole Gateway layer
healthy merely because the MCP capability is available.

The LayerDeployment status contract now carries per-component state for:

* MCP Gateway;
* MaaS Gateway;
* identity and exposure; and
* routing, quotas, and conformance.

The same status response now carries the Gateway layer's demoable use cases:

* authenticated MCP tool federation through `initialize`, `tools/list`, and an
  approved non-destructive `tools/call`;
* a governed model response through the MaaS Gateway; and
* policy, exposure, and conformance troubleshooting using the generated
  evidence.

The AI Hub experience renders these states after the guided installation. MCP
Gateway is marked healthy only when the executable path completes. MaaS and
the remaining cross-cutting Gateway capabilities remain visibly marked as
validation gates until their real checks pass. This keeps the user-facing
workflow honest while giving the customer an immediate path to value and a
clear next evaluation action.

This preserves the Project Matrix rule that every horizontal installer ends in
a usable evaluation, and that every future vertical/use-case installer must
consume the same layer contract rather than inventing a parallel workflow.

## AI Hub evaluator authorization gate — 2026-11-06

The upstream AI Hub MCP installer performs a SubjectAccessReview for the
browser identity before starting an MCP deployment. The live failure was
reproduced and isolated: the browser user `JayDi11a` had namespace `view`
access in `mcp-gateway-preview`, but lacked `create` on
`mcpservers.mcp.x-k8s.io`. The dashboard service account had the platform
read permissions; `kube:admin` CLI access was unrelated to the browser OAuth
identity.

The live cluster was corrected by binding the existing
`project-matrix-gateway-installer-user` Role to `JayDi11a` only in the
dedicated Gateway preview namespace. The resulting checks are positive for
the required MCPServer lifecycle verbs, while operator and Gateway API reads
remain delegated to the dashboard service account.

The reusable implementation now ships the namespace-scoped Role and a
platform-admin bootstrap script that accepts an explicit evaluator user or,
preferably, an IdP-backed evaluator group. No customer identity is hard-coded
in the product manifests. This is a one-time cluster/project entitlement, not
an end-user installation step, and it preserves the no-cluster-admin user
experience across arbitrary OpenShift AI clusters.

## Live AI Hub status-flow refinement — 2026-11-06

The upstream AI Hub slice was extended to make installation status durable and
truthful. The installer modal now remains the authoritative view while the
deployment is non-terminal; its close action and completion action stay
disabled until the real MCP deployment and Gateway registration conditions
resolve or fail. After the modal is closed, the deployment row exposes **View
installation status**, and the status view can be reopened through a durable
installation query parameter. This prevents a user from losing the status
stream by navigating to the catalog or deployments view.

The deployment status contract now distinguishes the cluster-local backend
Service URL from the externally exposed Gateway endpoint. The former is
copy-only and is not expected to open in a browser; the latter is the client
endpoint when Gateway registration publishes one. The deployment is not
reported as Available until the MCP server is ready and Gateway registration,
when present, is Ready.

The live RHOAI dashboard was rebuilt from the upstream worktree in RHOAI mode,
published to the project Quay repository, and rolled out by immutable digest to
the managed `rhods-dashboard` Deployment. Both dashboard replicas are healthy
and the route responds. The rollout changed only the dashboard image and its
least-privilege image-pull access; it did not modify OpenShift AI operators or
shared Gateway resources.

The next human validation is to open AI Hub, start or inspect the MCP
installation, confirm that the status modal cannot be dismissed while active,
close it only after a terminal state, then use the deployment row action to
reopen the same live status. This is the current Project Matrix Gateway
horizontal milestone; MaaS Gateway, authenticated MCP usability, identity and
exposure, routing/quotas, and conformance remain subsequent layer gates.

## Installation status truthfulness correction — 2026-11-06

The first live status refinement still allowed a misleading state after a
teardown/reinstall: a same-named prior deployment could be mistaken for the
current run, and the user could be left with indefinite generic spinners. The
upstream implementation now retains the object returned by the create request
and matches polling results by its UID, with a creation-time fallback only when
the cluster does not return a UID. Completion requires that current deployment
to be observed with Ready=True and, when required, GatewayRegistration=True.

While the run is active, Close and View installation status remain disabled.
The modal now reports the current phase, elapsed time, selected lane, polling
source, and a long-running explanation after 30 seconds. Gateway registration
also reports its actual state instead of combining a pending icon with a
completed-looking message.

The corrected RHOAI image was rebuilt from the upstream worktree and rolled to
the live managed dashboard at immutable digest
`sha256:eb363d46da29ee35fb7c8ee4f5b61252bb1c6ccb76a639b0653612298339dcee`.
Both dashboard replicas are healthy. Human validation must use a fresh browser
session and a new install after deleting the prior test deployment; an already
completed deployment cannot demonstrate the active-run state.

## One-click workflow correction — 2026-11-08

The active installer modal no longer exposes **View installation status**. That
action was a workflow error: it allowed an unfinished one-click operation to
hand the user to Deployments, where a partially reconciled resource could look
complete. During installation, the modal is the only status surface and has no
route-changing action. It remains open until the cluster reports success or a
blocked condition. Durable status inspection is reserved for the completed
deployment row and operational follow-up.

The corrected RHOAI dashboard image was built and rolled to the live cluster at
immutable digest
`sha256:8bab3ade8366afff9accff95b2513e536e4e0757ecb1c9fb5dbb0e6339324cc8`.
The managed dashboard is healthy with two available, updated replicas.

## AI Hub click-path reduction and live remote rollout — 2026-11-08

The MCP installer is served by the federated `model-registry-ui` module, not by
the main dashboard image. The first dashboard-only rollout therefore could not
change the installer visible in AI Hub. The module was rebuilt from the
upstream worktree and rolled to the live `model-registry-ui` Deployment at
immutable digest
`sha256:bcce1af42ada1538aed71ca60bd0aa1dca251547a6fc645c25d867d65e1609e8`.

The catalog flow now removes the redundant Review installation step. Production
remains the default; when the cluster requires the Technology Preview Gateway,
the evaluator explicitly enables Innovation and then starts the install from
the same view. The active modal remains the authoritative status surface and
does not provide a route-changing status button while work is in progress.

The live remote rollout initially referenced a stale local digest and entered
`ImagePullBackOff`; this was corrected to the canonical Quay manifest digest.
The existing namespace-scoped Quay pull secret was refreshed and attached only
to the module Deployment. The new replica is Ready. The remaining validation
is browser confirmation of the reduced flow and a fresh teardown/reinstall.

## Uninstaller cleanup verification — 2026-11-09

The Gateway-layer uninstaller now waits for the cluster to confirm deletion,
not merely acceptance of the delete request. It verifies that the owned
MCPServer, registrations, routes, grants, RBAC, configuration, and
operator-owned dependents are gone before returning success. Layer removal
also waits for Project Matrix-owned Gateway resources to disappear while
leaving shared platform services untouched.

The active UI keeps the cleanup operation visible with an explicit
**Waiting for cluster cleanup** state. A cleanup timeout returns a blocked
result instead of reporting a false success. Focused repository and UI tests
pass; the updated federated `model-registry-ui` is live on the evaluation
cluster and healthy. The next validation is a fresh install followed by
uninstall, confirming that the dialog remains active until the owned
resources are actually gone.

The live module was rebuilt for Linux/amd64 and rolled successfully after
correcting the registry pull and host-architecture issues. The running pod
observes the new Quay image at digest
`sha256:4ebd80f882577f9cb8f51b7de155fdd77694446a265c4c81af7a3df2bae10948`.
The image was built through the repository-supported
`packages/model-registry/Dockerfile.workspace` path, which is now the
reproducible build path for this live validation lane.
