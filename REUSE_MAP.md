# Project Matrix reuse map

This document records what Project Matrix can reuse from adjacent work without
weakening its OpenShift AI-native, Red Hat-centric architecture.

## Decision summary

| Source | Best fit in the Red Hat AI: Agentic Strategy | Reuse decision | Boundary |
|---|---|---|---|
| [openshift-ai-gateway-use-cases](https://github.com/jcordes73/openshift-ai-gateway-use-cases) | **Gateway (Gatekeeper)**, with future inputs to OGX/Bridge, Secure Agent Onboarding/Bastion, and AgentOps/Lens | Reuse as versioned capability fixtures, validation flows, and troubleshooting examples | Do not make the repository itself the controller or copy raw YAML into the product without normalization |
| [openshift-ai-ansible](https://github.com/jcordes73/openshift-ai-ansible) | **Infrastructure (Bedrock)** and outer bootstrap automation | Reuse role/check patterns and optionally invoke it from an outer provisioning workflow | It is AWS-oriented and provisions OpenShift AI; it is not a hard dependency for an already-installed OpenShift AI instance |
| Local OpenClaw installer | OpenShift AI UI/control-plane integration pattern; indirectly supports every layer | Reuse the dashboard extension, BFF, Job, Secret reference, validation, and status presentation patterns | Do not copy OpenClaw's application-specific CronJob/validation semantics as Project Matrix lifecycle authority |
| [rhoai-customer-workflows Aramock](https://gitlab.com/redhat/rhel-ai/workflow-validation/rhoai-customer-workflows/-/tree/main/scripts/cluster-management/aramock) | Cross-layer fixture/bootstrap and Aramco acceptance validation | Reuse its guarded preflight, MaaS/OIDC/Gateway fixtures, observability checks, rollback discipline, and customer workflow specs | Do not run the full bootstrap from the Gateway click; it can provision GPUs, patch cluster-wide Proxy/Image/DSC state, and assumes AWS or IBM Cloud VPC |

## Gateway use cases → Gatekeeper profiles

The gateway repository is directly useful for the first horizontal one-click
layer. Its current capability families map cleanly to Gatekeeper evaluation
profiles:

| Existing capability | Gatekeeper treatment |
|---|---|
| MCP Gateway, HTTPRoutes, MCP registrations, AuthPolicy/Authz, and Kuadrant/Authorino resources | Gateway production/innovation fixtures and readiness checks |
| OpenShift MCP server | The default end-to-end MCP reference path for the Saudi Aramco evaluation |
| External Models, providers, MaaS model references/subscriptions, and auth policies | Optional MaaS/external-model profile; credentials remain Secret references supplied by the customer |
| OGX server/configuration | A future Bridge adapter/profile, not silently included in the Gateway click |
| NeMo Guardrails | Future AgentOps/Lens or gateway-policy profile, with explicit support status |
| Keycloak import and identity examples | Optional Bastion/Gatekeeper identity fixture, subject to customer identity and support review |

The repository is a use-case kit, not a reconciler. Project Matrix should
translate selected examples into a stable profile contract with pinned
versions, namespaces, ownership, preflight checks, production/preview
support labels, and post-install evidence. The original examples remain
valuable as human-readable troubleshooting material and as the source for
conformance tests.

## OpenShift AI Ansible → Bedrock and outer automation

The Ansible project is useful for environments where the surrounding cluster
or OpenShift AI installation is also part of the deliverable. Its role
structure can inform an outer installer for cluster prerequisites, GPU/NFD,
Kueue/LWS, observability, and OpenShift AI enablement.

For the current Project Matrix entry point, OpenShift AI is assumed to already
exist. Therefore the Ansible project should remain an optional outer adapter:

```text
Terraform or site automation
  -> Ansible/bootstrap (optional, environment-dependent)
  -> OpenShift AI installed and healthy
  -> Project Matrix controller
  -> Gatekeeper Gateway profile
```

The AWS assumptions, pull-secret handling, Automation Hub access, vault
credentials, and cluster provisioning behavior must not leak into the inner
controller or the dashboard. Other infrastructure flavors need their own
Bedrock adapter or a pre-existing-cluster contract.

## Aramock → cross-layer fixtures and acceptance evidence

The inspected Aramock snapshot (`e39026a31c8a41bf77edaa7b4a900326fddb7ef7`)
is a persistent RHOAI 3.5 customer-workflow fixture suite, not merely a mock
server. It covers:

| Aramock capability | Project Matrix mapping |
|---|---|
| Exact API-target guard, preflight, ownership labels, idempotent setup, explicit destroy confirmation | Controller/runner safety contract and inspectable troubleshooting assets |
| DSC MaaS enablement, Gateway/Route readiness, MaaSModelRef, MaaSAuthPolicy, MaaSSubscription, ExternalModel | Gateway/Gatekeeper profile fixtures and conformance checks |
| Keycloak direct OIDC, Authorino issuer trust, service-account and group-based access | Secure Agent Onboarding/Bastion integration checks; optional identity fixture, never a hardcoded identity dependency |
| LLMInferenceService simulator and Qwen model path | vLLM (Core)/llm-d dependency fixtures and evaluation backends; not part of every Gateway install |
| Prometheus/MaaS telemetry and custom metrics | AgentOps/Lens evidence and post-install acceptance checks |
| AWS/IBM GPU MachineSets and optional Qwen capacity | Infrastructure/Bedrock adapter material only; outside an OpenShift AI-already-installed inner click |
| Gateway ClusterIP, Route, proxy, registry allowlist, DNS, CA, and rollback tooling | Bedrock/network preflight and dedicated infrastructure experiment; never silently applied by Gatekeeper |
| Aramco Playwright workflows for deployment, service-account access, external models, and metrics | Customer-facing Gatekeeper evaluation/conformance suite after installation |

The strongest reusable design patterns are the exact-cluster guard, fail-before
mutation preflight, explicit ownership labels, server-side dry runs, bounded
readiness gates, credential-free state snapshots, conflict-aware restore, and
clear separation between temporary validation fixtures and persistent setup.

The main architectural warning is scope. Aramock's `setup.sh` is intentionally
broader than Project Matrix's Gateway layer: it can enable MaaS, create
namespaces and identities, provision cloud GPU MachineSets, modify dashboard
configuration, and optionally modify cluster-wide image or proxy state. It
therefore should be decomposed into Project Matrix-owned capability profiles,
not invoked wholesale from the UI.

The immediate Gatekeeper reuse slice is:

```text
Existing OpenShift AI and Gateway prerequisites
  -> guarded Gatekeeper preflight
  -> optional namespaced simulator / identity fixtures
  -> MaaS/MCP Gateway validation
  -> Aramco conformance workflow
  -> evidence ConfigMap and downloadable diagnostics
```

The first executable Aramock reuse is intentionally read-only: Gatekeeper's
innovation evaluation invokes a conformance check for the MaaS Gateway,
Aramock simulator, MaaSModelRef, MaaSAuthPolicy, MaaSSubscription, and an
optional MaaS endpoint. This provides immediate value from Aramock without
making its bootstrap, cloud provisioning, or cluster-wide network experiments
part of the Gateway click.

GPU provisioning, cluster-wide proxy/image policy, DNS cutover, and destructive
MaaS Gateway reset remain explicit Bedrock operations with separate approvals,
ownership, and rollback—not hidden consequences of the Gateway one-click.

## OpenClaw/ODH → Project Matrix UI

The OpenClaw work demonstrates a useful dashboard lifecycle:

```text
Dashboard extension
  -> authenticated dashboard/BFF request
  -> Kubernetes Job or controller action
  -> validation/status resource
  -> dashboard polling and "Open application"/next action
```

Reusable UI-side assets and patterns include:

- ODH Dashboard module-federation metadata and extension points;
- PatternFly/React presentation and Tech Preview labeling;
- an authorized BFF/proxy boundary rather than browser-held cluster credentials;
- Job-trigger and minimal-RBAC integration patterns;
- status/evidence presentation and troubleshooting links.

Project Matrix changes the lifecycle authority: the dashboard should create or
patch a `LayerDeployment`, and the Project Matrix controller owns dependency
resolution, Job creation, conditions, evidence, and remediation. The UI should
present the single `Preview capabilities: OFF | ON` switch plus phase,
support boundary, conflicts, evidence, and troubleshooting—not a generic
OpenClaw-style deployment form.

## Immediate implementation consequence

The next reuse task is to create a Gatekeeper profile-source catalog from both
the Gateway use-case examples and the Aramock fixture contracts, beginning with
MCP Gateway, OpenShift MCP, MaaS/OIDC, and the Aramco conformance path.
Each source manifest will be classified as:

1. production-supported;
2. innovation/technology-preview;
3. customer-supplied configuration; or
4. reference-only troubleshooting material.

No external repository becomes a runtime dependency until its resources have
passed that classification and are represented by a Project Matrix-owned
contract.
