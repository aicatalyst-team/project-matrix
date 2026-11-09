# Project Matrix image release lock

Release date: 2026-10-21

Quay is the canonical `aicatalyst` release registry. The OpenShift integrated
registry is the cluster-local mirror used to avoid external pull dependencies
inside the target cluster.

The prior baseline references remain below for audit history. The
2026-10-20 validation images were promoted from the live OpenShift registry
and independently verified in `aicatalyst`.

## Canonical Quay images

```text
quay.io/aicatalyst/project-matrix-controller@sha256:4bc86b0302e2de21477319425e18b639c5ee957caf369f0a1c06bb19e344df02
quay.io/aicatalyst/project-matrix-gatekeeper@sha256:6a1036aed227d022021778f59ea72e6e37de9dc7586a8b094dc6da31845566cb
```

## Promoted validation release — 2026-10-20

These immutable references are the canonical Quay promotion of the live
validation images. The tag is retained as a human-readable release alias;
deployment references must use the digest.

```text
quay.io/aicatalyst/project-matrix-controller@sha256:8754427dfcd4ef78fd9d01f5eb91e017c647eafdaed2d0d2ac6be9384f87c1bc
quay.io/aicatalyst/project-matrix-gatekeeper@sha256:4cd336e499183fe10a0ccc29268e54ee11ea2e16e410ce491f0b5f281ea6f0bf
quay.io/aicatalyst/project-matrix-dashboard@sha256:8e231e6be16f4900e2e9a41841a36b0daef1040547597f479953a3fcfd93550d
```

Human-readable aliases:

```text
quay.io/aicatalyst/project-matrix-controller:20261020-gateway-layer
quay.io/aicatalyst/project-matrix-gatekeeper:20261020-gateway-layer
quay.io/aicatalyst/project-matrix-dashboard:20261020-gateway-layer
```

## Target-cluster mirror images

```text
image-registry.openshift-image-registry.svc:5000/matrix-system/project-matrix-controller@sha256:98a2a4c5a530c2ab03715be1bfe20f71f3d790b1ed8007aef1ebd319bd583a77
image-registry.openshift-image-registry.svc:5000/matrix-system/project-matrix-gatekeeper@sha256:b12e3ea263559146a3508bdbc13fe738b82057105dfa14894f8f6054a2289e24
```

The dashboard reference above is the Project Matrix BFF image. The combined
OpenShift AI Dashboard host image is still pending because its static
federated bundle must be built inside the compatible Dashboard host workspace.
The independent remote build is validated in
`evidence/gatekeeper-delivery-quality-2026-10-19.md`; the host-integrated
Dashboard image receives its own digest at release time.

## Live-cluster validation build — 2026-10-20

These are the immutable images built natively by the target OpenShift 4.21
cluster for teardown/reinstall validation. They are intentionally scoped to
the isolated `project-matrix-build` evaluation namespace and are not the
canonical external shipment references above:

```text
image-registry.openshift-image-registry.svc:5000/project-matrix-build/project-matrix-controller@sha256:8754427dfcd4ef78fd9d01f5eb91e017c647eafdaed2d0d2ac6be9384f87c1bc
image-registry.openshift-image-registry.svc:5000/project-matrix-build/project-matrix-gatekeeper@sha256:4cd336e499183fe10a0ccc29268e54ee11ea2e16e410ce491f0b5f281ea6f0bf
image-registry.openshift-image-registry.svc:5000/project-matrix-build/project-matrix-dashboard@sha256:8e231e6be16f4900e2e9a41841a36b0daef1040547597f479953a3fcfd93550d
image-registry.openshift-image-registry.svc:5000/project-matrix-build/project-matrix-dashboard-host@sha256:76c1eab9c9c7b509aecb22789025473fad9dcb46c2d2a3a19bdfb717ed9f8360
```

## Project Matrix naming release — 2026-10-21

The renamed Matrix source was built natively by the target OpenShift cluster.
These are immutable, cluster-local release references for the Matrix migration:

```text
image-registry.openshift-image-registry.svc:5000/project-matrix-build/project-matrix-controller@sha256:69e155c8cb25eb5bbf5025894a9b525958a13bb36add05ff72a28fc45b3da5f8
image-registry.openshift-image-registry.svc:5000/project-matrix-build/project-matrix-gatekeeper@sha256:4bd8096ed342d353cce15ae04b38a68f60480714f35fe015dbcf25948a5d7411
image-registry.openshift-image-registry.svc:5000/project-matrix-build/project-matrix-dashboard@sha256:b1ed7635dc3d6b920014a3a2e8ebbce9d924f7426459514ecce6626b98bfa63c
```

The optimized Matrix release image metadata is:

```text
project-matrix-controller   62.8 MB
project-matrix-gatekeeper  124.6 MB
project-matrix-dashboard    52.8 MB
project-matrix-dashboard-host 274.4 MB
```

The Gatekeeper image was reduced from 472.4 MB to 124.6 MB by replacing the
full Python UBI runtime with `ubi-minimal` plus only the required runtime
packages. The optional customer-workflow Python helpers remain available.

The content is the same release source used for canonical promotion. The
cluster build namespace exists only to validate the installation lifecycle;
the Project Matrix teardown script does not remove it because it is not part of
the shipped control-plane ownership set.

The corrected Matrix-named host build completed successfully through the
native OpenShift AI Dashboard production build path. It includes the
first-party host landing-page card source and is the current isolated
evaluation reference:

```text
image-registry.openshift-image-registry.svc:5000/project-matrix-build/project-matrix-dashboard-host@sha256:6b8060a28237430a8b3a88e39ef9e3ed1e7791f8a83dd873b10519d2df8ee79a
```

This cluster-local digest is not yet a canonical Quay promotion.

## AI Stack UX and status contract — 2026-10-21

The live Matrix runtime and isolated Dashboard host were rebuilt after the
user-facing terminology and layer-specific status contract were refined:

```text
image-registry.openshift-image-registry.svc:5000/project-matrix-build/project-matrix-controller@sha256:64195518ca33fe6f0d02a6ad3d272cd19b30639067f67e672ed063332457cabd
image-registry.openshift-image-registry.svc:5000/project-matrix-build/project-matrix-dashboard@sha256:ae40b0d64b15d6f377fe3687b58223338a4d6ae87bf40024e1f0e2020e73945d
image-registry.openshift-image-registry.svc:5000/project-matrix-build/project-matrix-dashboard-host@sha256:9927d10c096e131a16d291530a2640b57cc1b15562b8fb5ffd7fe1845090d66b
```

The controller now publishes `status.currentStep`, allowing the Dashboard to
show what the selected layer is actually doing or why it is blocked. The
evaluation installer also uses a bounded host-build context and immutable
sidecar references.

## AI Stack layered landing page — 2026-10-21

The isolated host was rebuilt after the installer experience was expanded from
a Gateway-only page into the Red Hat AI Stack landing page. The host now shows
the horizontal layers in their architectural order, with Gatekeeper as the
first available guided installer:

```text
image-registry.openshift-image-registry.svc:5000/project-matrix-build/project-matrix-dashboard-host@sha256:a5d04572679cbf1c2bebf8373c85f000fcc15d2e0a50deffcc63121ea170cddc
```

This is the current cluster-local evaluation digest. It is not yet a
canonical Quay promotion and does not replace the operator-managed native
Dashboard.

## Interactive stack-map installer — 2026-10-21

The isolated evaluation host was rebuilt with the code-native interactive
stack map. Its layer bands are selectable and use drawing-inspired hover,
focus, lift, shading, and contextual installer treatment:

```text
image-registry.openshift-image-registry.svc:5000/project-matrix-build/project-matrix-dashboard-host@sha256:184bf7a80c1ae2e92cf82beb59da45620616cd9e540c547f5e93ef3aa35fea0d
```

The digest is live on `project-matrix-dashboard-eval` and remains isolated
from the operator-managed native Dashboard.

Do not commit registry credentials. A cluster deployment may use the internal
mirror directly, or use the Quay references with an approved image-pull
secret.

## Exact supplied stack artwork and minimal installer rail — 2026-10-21

The isolated Dashboard host now uses the supplied hand-drawn platform-stack
artwork as its primary visual surface. Transparent layer hotspots provide
keyboard-accessible selection and subtle hover lift without replacing the
artwork with a CSS approximation. The Gateway selection uses the minimal
OpenClaw-like one-action installer rail and live LayerDeployment status.

image-registry.openshift-image-registry.svc:5000/project-matrix-build/project-matrix-dashboard-host@sha256:8d44afe0da81929d7c00dafb425e44da0ad4eb309ebfbb10ff23fe8a0bc4318c

This digest is live on the protected project-matrix-dashboard-eval route.
The host smoke checks pass; browser acceptance remains required before the
GitHub milestone push.

## From-scratch SVG artwork and workflow state — 2026-10-22

The raster artwork implementation is superseded. The current host renders the
stack from scratch as an interactive SVG and implements the OpenClaw workflow:
installation preview before the action, followed by live controller-owned
status until completion or a truthful gate.

image-registry.openshift-image-registry.svc:5000/project-matrix-build/project-matrix-dashboard-host@sha256:618983d55689f25dfb4469823e61d08a8752586476b7c8446876703118637f0c

This digest is live on project-matrix-dashboard-eval. No screenshot asset is
required by the current implementation.

## Artwork cleanup — 2026-10-22

The live host now uses a transparent SVG canvas, no surrounding layer arrows,
and the intended colored bands. The marker-wobble filter was removed because
it could render the fills black in the host browser.

image-registry.openshift-image-registry.svc:5000/project-matrix-build/project-matrix-dashboard-host@sha256:a4c7b72bb84e063759f8c2f83cc98181679155ecb6ca004d4a3781d6291722c3

This digest is live on project-matrix-dashboard-eval and remains isolated
from the operator-managed native Dashboard. Browser acceptance is the
remaining gate before the GitHub milestone push.

## Foreground layer interaction and reliable concept motion — 2026-10-22

The dashboard host now loads with every layer fully visible. An explicit layer
selection creates the focus state: the selected band lifts above the stack and
non-selected bands recede into the background. The selected band remains the
primary lift; its individual concepts use dedicated SVG wrapper elements with
staggered motion so icons, labels, and pills visibly acknowledge the selected
layer without fighting the layer transform.

image-registry.openshift-image-registry.svc:5000/project-matrix-build/project-matrix-dashboard-host@sha256:613521718598be5f145d3f769cac1bb829ce7eade262312f6dd902406ff70a5d

This digest is live on project-matrix-dashboard-eval. The protected route
returns OAuth 302, the direct route returns 401, and the deployed pod is
healthy with all three containers ready. Browser acceptance remains the final
UI gate before the GitHub milestone push.
