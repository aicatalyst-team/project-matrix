# Project Matrix technology baseline

## Platform identity

Project Matrix is explicitly a **Red Hat OpenShift AI solution**. OpenShift AI
Self-Managed on OpenShift is the platform contract; generic Kubernetes is not a
supported target for the primary product experience.

Portability means that the same open interfaces and layer contracts can run
across Red Hat OpenShift footprints—including public cloud, on-premises,
disconnected, and air-gapped environments—
without replacing the Red Hat operating model with a generic Kubernetes layer.

The implementation priority is:

1. Red Hat-supported OpenShift AI and OpenShift capabilities;
2. Red Hat-supported automation and provisioning tools, including Ansible and
   Terraform, where appropriate to the layer;
3. upstream/open-source implementations and downstream-compatible images where
   they preserve the same contract and improve disconnected or customer-owned
   operation.

## Primary deployment architecture

```text
OpenShift AI UI
   -> LayerDeployment CR
      -> Go controller / dependency resolver
         -> Argo CD Application + Kustomize profile
            -> OpenShift AI, Gateway, inference, identity, and AgentOps APIs
         -> Kubernetes Jobs for validation, evaluation, and diagnostics
      <- conditions, evidence, support boundary
```

## Technology choices

| Concern | Technology | Role |
|---|---|---|
| Deployment API | Kubernetes CRD: `LayerDeployment` | Stable desired-state contract for every horizontal layer. |
| Reconciliation | Go, Kubebuilder, controller-runtime | Watches desired state, resolves dependencies, applies changes, and publishes status. |
| Packaging | Operator SDK and OLM | Installs the Project Matrix controller in a Red Hat/OpenShift-native way. |
| Resource delivery | Argo CD plus Kustomize | Applies versioned production and preview profiles with drift detection and rollback. |
| Dependency policy | Typed Go dependency graph plus CEL constraints | Detects version, ownership, route, namespace, and coexistence conflicts before mutation. |
| Validation/evaluation | Kubernetes Jobs; Tekton only for multi-stage pipelines | Runs preflight, conformance, MCP-to-MaaS evaluation, diagnostics, and evidence collection. |
| UI | React/TypeScript with PatternFly | Presents the single Production/Preview operating-mode switch and status. |
| Authentication | OpenShift OAuth and Kubernetes RBAC | The UI never receives cluster-admin credentials. |
| Secrets | OpenShift Secret references, with External Secrets/Vault integration where required | Credentials remain cluster-side and are never embedded in profiles or reports. |
| Observability | Kubernetes Conditions, Events, Prometheus, OpenTelemetry, and MLflow | Makes controller, request-path, evaluation, and support evidence visible. |
| Evidence | ConfigMap/PVC for local runs; S3-compatible object storage when available | Stores reports without putting secrets in Git. |

## Red Hat capability alignment

The controller and profiles must use the capabilities already present in the
Red Hat AI: Agentic Strategy stack before introducing independent substitutes:

- OpenShift Operators, OLM, Routes, Gateway API, OAuth, SCC, RBAC, storage,
  scheduling, and cluster observability;
- Red Hat OpenShift AI Dashboard, AI Hub/MCP Catalog, DataScienceCluster,
  Models-as-a-Service, KServe, vLLM, llm-d, OGX, MLflow, TrustyAI, and the
  OpenShift AI model/tool lifecycle capabilities available in the target
  release;
- Red Hat Connectivity Link, its Gateway/MCP capabilities, Authorino,
  Limitador, and Red Hat build of Keycloak where selected and supported;
- OpenShift GitOps, OpenShift Pipelines, OpenTelemetry, and OpenShift Logging;
- Terraform for infrastructure provisioning where the target environment
  requires it, without making an IBM Cloud or other external service a runtime
  dependency;
- Ansible Automation Platform/Ansible for host, cluster, registry, disconnected,
  and operational automation where appropriate, without making Ansible the
  inner Kubernetes reconciliation engine.

IBM ownership of Red Hat and HashiCorp is context for the toolchain, not an
integration requirement. Project Matrix has no IBM Cloud, watsonx, or other IBM
service runtime dependency.

Where a Red Hat downstream is not available in the selected lane, the profile
may use the upstream/open-source project—such as Gateway API, KServe, vLLM,
llm-d, MLflow, OpenTelemetry, Argo CD, or Tekton—provided that the report names
the exact implementation, support tier, image, and promotion path. The API
contract remains open; the validated deployment profile remains Red Hat
OpenShift AI-specific.

## Platform preflight requirements

The controller must fail before mutation when the target is not the intended
platform or when the supported configuration is not satisfied. At minimum it
must verify:

- OpenShift identity and version;
- OpenShift AI Operator and `DataScienceCluster` readiness;
- target OpenShift AI supported configuration;
- required Red Hat Operators, CRDs, and channels;
- OpenShift AI Dashboard integration points;
- OpenShift Gateway API, Routes, OAuth, SCC, storage, and observability;
- selected external service prerequisites only when a profile explicitly
  declares them as a customer dependency;
- disconnected/air-gapped registries and mirrored content when applicable.

## Ownership boundaries

- The UI owns user intent only: desired state and the Production/Preview mode.
- The Project Matrix controller owns `LayerDeployment` status, dependency
  resolution, profile selection, and lifecycle coordination.
- Argo CD owns the child resources produced by a selected profile.
- Kubernetes Jobs own repeatable validation and evaluation execution.
- Project Matrix never silently owns or removes shared Operators, customer
  namespaces, customer data, or unrelated Service Mesh resources.
- Existing shell scripts remain downloadable troubleshooting tools and become
  the first Job implementation for Gatekeeper; they are not the long-term
  reconciliation engine.

## Why this baseline

The control plane must be Kubernetes-native because the desired outcome is a
long-lived, drift-aware platform state across hybrid and multi-cloud OpenShift
instances. Go/controller-runtime provides typed reconciliation and conditions;
Argo CD/Kustomize provides auditable profile delivery; Jobs preserve the
customer's inspectable scripts. Terraform and Ansible may participate in the
Infrastructure layer, but they should not be the inner orchestration engine for
OpenShift AI layer activation.

## Red Hat product-quality bar

Project Matrix is being designed as a candidate Red Hat/OpenShift AI solution,
not as a customer-specific automation bundle. “Works on one cluster” is not a
release bar. Every horizontal layer and later vertical must be contribution-
ready, supportable, secure, operable, and explainable through the Red Hat AI:
Agentic Strategy vocabulary.

Before a layer is promoted, its acceptance gate must cover:

- a PatternFly/OpenShift AI-native user experience with one opinionated action;
- least-privilege RBAC, explicit ownership, secret hygiene, and fail-before-
  mutation preflight;
- production and preview support boundaries, version and upgrade behavior,
  rollback, disconnected/air-gapped content, and exact image provenance;
- Kubernetes Conditions, Events, Prometheus/OpenTelemetry evidence, bounded
  diagnostics, and customer-readable troubleshooting;
- automated unit, render, conformance, upgrade, and hybrid-footprint tests;
- documented APIs and profile contracts that are open-source/downstream
  compatible and do not encode IBM runtime dependencies or customer names; and
- an upstream/downstream promotion path with licensing, contribution, release,
  and support documentation suitable for Red Hat engineering review.

Aramock, Saudi Aramco workflow assets, and other customer-derived material can
inform fixtures and acceptance knowledge, but the product boundary must remain
general, consented, provenance-tracked, and reusable. This is the standard by
which Project Matrix will be judged before any claim of end-to-end completion.
