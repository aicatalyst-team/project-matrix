# Aramock collaboration boundary

Project Matrix intends to work closely with the team responsible for Aramock.
This document keeps that collaboration explicit and prevents an accidental
fork or a confusing transfer of ownership.

## Collaboration intent

Aramock contains the strongest existing Saudi Aramco customer-workflow context
for MaaS, OIDC, External Models, Gateway behavior, observability, and the
cloud/network conditions around RHOAI. Project Matrix should amplify that work
by making it reachable through a simple, opinionated OpenShift AI experience.

The relationship is:

```text
Aramock team owns customer-workflow fixtures and acceptance knowledge
                ↓ pinned, classified integration contract
Project Matrix owns LayerDeployment, profiles, controller lifecycle, UI, and evidence handoff
```

## Ownership boundaries

| Area | Primary owner | Project Matrix treatment |
|---|---|---|
| Aramco workflow narratives and Playwright specs | Aramock/customer-workflow team | Invoke or reference as post-install acceptance evidence; preserve source provenance |
| Cloud/GPU/network fixture bootstrap | Aramock/cluster-management team | Consume selected preflight and fixture contracts; keep provider-specific mutation outside Gatekeeper |
| Gateway/MaaS/OIDC capability definitions | Shared | Agree on a versioned capability manifest and support classification |
| `LayerDeployment` and dependency resolution | Project Matrix | Controller-owned; Aramock does not become a controller dependency |
| OpenShift AI UI and one-click experience | Project Matrix | UI patches intent and presents status/evidence; it does not run arbitrary Aramock scripts |
| Customer troubleshooting scripts | Shared | Retain inspectable scripts and link them from Project Matrix evidence |

## Recommended integration model

Use a pinned-source integration model first:

1. Record the Aramock repository URL and tested revision in the Gatekeeper
   profile catalog.
2. Classify each candidate script or fixture as read-only preflight,
   namespaced fixture, cross-layer dependency, cluster-wide mutation, or
   reference-only workflow material.
3. Agree on a small machine-readable capability/result contract.
4. Run the selected acceptance workflows after `LayerDeployment` reaches
   `Ready` or `Evaluating`.
5. Publish the workflow result, source revision, logs, and diagnostics through
   the Project Matrix evidence reference.
6. Only then consider packaging a stable subset into the Gatekeeper executor
   image, subject to licensing, release, and ownership review.

The first shared contract should cover:

- target cluster identity and exact-target safety;
- RHOAI/OpenShift version and required CRDs;
- production versus innovation support lane;
- required fixture capabilities;
- resources created and resources deliberately not touched;
- readiness and acceptance checks;
- cleanup/rollback responsibility; and
- credential and evidence handling.

## Proposed near-term collaboration agenda

1. Review the Project Matrix profile catalog with the Aramock team.
2. Agree which Aramock cases represent the Gateway layer versus dependencies
   in vLLM (Core), llm-d, Secure Agent Onboarding, and AgentOps.
3. Select one minimal namespaced evaluation fixture that can run from a
   pre-existing OpenShift AI cluster without GPU or cluster-wide mutation.
4. Define how Project Matrix launches or links the Aramco conformance workflow.
5. Compare evidence schemas and identify the smallest common result bundle.
6. Establish a revision/update cadence so Project Matrix does not silently
   drift from the Aramock team's supported workflow.

Until that collaboration occurs, Project Matrix will not copy or materially
rewrite Aramock scripts. It will use the inspected revision as provenance and
will keep any adapter narrow, reviewable, and reversible.
