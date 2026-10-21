# Gatekeeper upstream preview release evidence — 2026-10-19

## Decision

The innovation lane has one authoritative preview source:

```text
Repository: https://github.com/Kuadrant/mcp-gateway
Release:    v1.0.2
Commit:     e48ae51cfa52a57f93f334bdadbe8ce58ef5a9f6
Chart:      oci://ghcr.io/kuadrant/charts/mcp-gateway:1.0.2
Digest:     sha256:97be2a4ba4daae5b5a8470074c414a94c02689d3e9c3910eaa098f6044e42eb3
```

The Red Hat OLM-managed package is retained as the production/support
compatibility baseline. An upstream image or chart is not substituted into
that operator path.

## Same-cluster status

Read-only inventory of the validation cluster on 2026-10-19:

```text
OpenShift API: https://api.ocp-gb.ibm.redhataicatalyst.com:6443
RHCL CSV:      rhcl-operator.v1.4.3 / Failed (UnsupportedOperatorGroup)
RHCL channel:  stable
MCP package:   mcp-gateway.v0.7.1 / preview
```

The active RHCL subscription reports `rhcl-operator.v1.4.3` but its CSV is
`Failed/UnsupportedOperatorGroup`; a copied `rhcl-operator.v1.4.2` CSV is
present in the operator scope inventory. The upstream OpenShift deployment
declares RHCL 1.5.0 or newer. Because the cluster does not currently meet that
prerequisite, the isolated preview installer refuses to mutate the cluster.
No preview namespace, Helm release, operator subscription, or Gateway is
created by this refusal.

## Generalized Aramco contract

Gatekeeper now carries checks for:

- same-port public `mcp` and internal `mcps` listeners;
- real `sectionName` and `privateHost` Service/port resolution;
- unsupported HTTPRoute rule-field detection;
- Route, LoadBalancer, and ClusterIP exposure contracts;
- explicit `Gateway.spec.infrastructure.parametersRef` reporting for portable
  ClusterIP deployments;
- HTTPS certificate-reference Secret discovery when TLS terminates at the
  Gateway;
- operator CSV scope and copied-CSV reporting;
- omission of `credentialRef` for unauthenticated backend registrations; and
- a separate `mcps` listener AuthPolicy contract.

The `gatekeeper/preview/install-upstream.sh` path is intentionally explicit and
isolated. It requires `GATEKEEPER_CONFIRM_UPSTREAM_PREVIEW=1` after the RHCL
prerequisite passes and labels the resulting Gateway with the pinned source,
version, and commit so Gatekeeper can verify provenance.

## Final same-cluster preflight results

The sequential read-only preflights on the target cluster completed with
collision-free evidence directories:

- Production: `failures=2`, `warnings=0`. The generalized topology, exposure,
  TLS, credential, isolation, DNS, and TokenReview checks passed. The two
  failures are the missing `mcps` AuthPolicy and the Red Hat MCP Gateway
  Technology Preview support gate.
- Innovation: `failures=2`, `warnings=2`. It correctly rejected the current
  unmarked Red Hat Gateway as not being upstream `v1.0.2` and rejected its
  `LoadBalancer` exposure as different from the pinned preview’s `ClusterIP`
  profile. The existing Route, TLS, isolation, and platform health checks
  passed.

The innovation lane now exits nonzero for an incorrect runtime contract while
continuing to allow bounded Technology Preview warnings.
