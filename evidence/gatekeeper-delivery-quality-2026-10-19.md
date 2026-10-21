# Gatekeeper delivery-quality review — 2026-10-19

This review covers the non-gating Project Matrix/Gatekeeper delivery boundary.
It does not convert a Red Hat Technology Preview dependency into supported
software and does not close the live MCP Gateway `mcps` or AuthPolicy gates.

## Result

The implementation package passes the static delivery-quality review. The
remaining release actions are external host/image actions, while the live
Gateway support and protocol gates remain explicit production blockers.

## Lean

- One `LayerDeployment` intent is the user-facing control surface.
- The Dashboard BFF is a narrow transport and authorization boundary; it can
  only read/create/patch the fixed `matrix-system/gatekeeper` resource.
- The controller owns reconciliation and the Gatekeeper Job owns the layer
  adapter. The BFF does not duplicate controller or Aramock workflow logic.
- The federated UI shares React, React Router, PatternFly, and Dashboard plugin
  dependencies with the host rather than creating a second platform runtime.

## Optimized

- Controller and BFF deployments have bounded CPU/memory requests and limits.
- Production frontend builds now omit source maps by default. A diagnostic
  build can opt in with `SOURCE_MAPS=true`.
- The built remote is 7.7 MiB including the standalone preview assets; the
  largest shared PatternFly fallback assets are approximately 1.3 MiB CSS and
  580 KiB JavaScript. The Dashboard host is expected to satisfy these shared
  dependencies at runtime. The sizes are recorded as an optimization baseline,
  not a production acceptance gate.
- The package has a lockfile and a host-contract validator so dependency and
  registration drift fails before image promotion.

## Robust

- Production remains the default and Preview is explicit.
- BFF requests are constrained, bounded to 64 KiB, reject unknown JSON fields,
  and reject namespace/profile mutation.
- Controller, BFF, and Gatekeeper tests pass; Kustomize renders as one install
  boundary; the federated remote and manifest validate.
- Gatekeeper fails closed on unsupported Gateway/AuthPolicy behavior and records
  diagnostic evidence without bearer tokens or response bodies.

## Secure

- Containers run non-root with RuntimeDefault seccomp, dropped capabilities,
  no privilege escalation, and read-only root filesystems.
- The BFF ServiceAccount has no Job, Gateway API, operator, or cluster-wide
  mutation authority.
- Release images remain immutable digest requirements. Example image references
  in manifests are intentionally not release-ready until promoted images are
  supplied.
- The host proxy is authorized and the browser cannot select arbitrary
  namespaces, manifests, profiles, or customer workflows.

## Validation evidence

```text
bash ui/validate-host-integration.sh --require-build  PASS
make -C ui validate-host                                  PASS
oc kustomize .                                             PASS
bash -n gatekeeper/gatekeeper.sh                               PASS
./gatekeeper/profiles/validate-catalog.sh                    PASS
GOCACHE=/tmp/project-matrix-go-cache go test ./...           PASS
```

## Boundaries still open

1. Register the package in the compatible OpenShift AI Dashboard workspace and
   publish the combined Dashboard image.
2. Promote and record an immutable dashboard BFF image digest; the current
   Kustomize image is a release placeholder.
3. Obtain the supported/approved Gateway support path, add the `mcps` listener,
   qualify runtime AuthPolicy enforcement, and run authenticated protocol
   evidence on the target cluster.
