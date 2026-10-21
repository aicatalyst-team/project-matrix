# Project Matrix naming convention

Project Matrix is the internal codename for the Red Hat AI: Agentic Strategy
horizontal one-click program. The official Red Hat layer name is always the
primary product language. The Matrix term is a secondary codename used for
orientation, storytelling, UI polish, and internal delivery artifacts.

## Canonical mapping

| Red Hat AI: Agentic Strategy layer | Project Matrix codename | Scope |
| --- | --- | --- |
| Infrastructure | **The Source** | OpenShift, RHEL AI, GPUs/TPUs, storage, networking, and platform services |
| vLLM (Core) | **The One** | Model-serving core and chat/tool-call inference |
| llm-d | **The Architect** | Disaggregated serving, routing, scheduling, and inference topology |
| OGX | **The Keymaker** | API translation, connectors, and protocol interoperability |
| Gateway | **The Gatekeeper** | MCP/MaaS ingress, routing, identity, authorization, quotas, and guardrails |
| Secure Agent Onboarding | **Trinity** | Trusted identity, SPIFFE/SPIRE, sandbox admission, and agent enrollment |
| AgentOps | **The Oracle** | Tracing, evaluation, cost, governance, observability, and evidence |
| BYOA | **Zion** | Customer-owned agents, frameworks, tools, and applications |

The first horizontal one-click deployment is **Gateway / The Gatekeeper**.
Existing live resources may carry an earlier technical identity during the
controlled migration; all new user-facing intent uses `Gatekeeper`.

## Operating lanes

| Official lane | Matrix treatment | Contract |
| --- | --- | --- |
| Production | **The Red Path** | Default, pinned, supported-capability candidate, and fail-closed |
| Innovation | **The Blue Path** | Explicit opt-in for Technology Preview, Developer Preview, early-access, or upstream capabilities |

The official `Production` and `Preview` values remain the API contract. Matrix
terms are explanatory labels and must never conceal a support boundary.

## Dashboard experience

The OpenShift AI Dashboard experience is **The Construct**. It presents the
official layer names, Matrix codenames, dependency relationships, lane,
support tier, readiness, evidence, and one-click action.

The fedora stack visualization is an interactive journey map:

- installed layers are active and selectable;
- uninstalled layers are available but visibly inactive;
- dependencies illuminate when a layer is selected;
- installing, ready, blocked, and degraded states use PatternFly status
  treatments and accessible text, not color alone; and
- every visual state has an equivalent list/table representation.

The visualization is a Dashboard presentation layer. The BFF and
`LayerDeployment` controller remain the only mutation path.

## Identifier policy

Human-facing documentation and UI use Project Matrix and the canonical layer
mapping immediately. Kubernetes names, image repositories, API groups, and
package names now use `project-matrix` or `gatekeeper`. The live cluster is
migrated through a versioned release rather than an ad hoc in-place rename.

Examples:

```text
Project Matrix / The Construct
  Gateway / The Gatekeeper
  Production / The Red Path
  Innovation / The Blue Path
```

The codename does not replace Red Hat product names, installed component
versions, support classifications, or customer-facing technical evidence.
