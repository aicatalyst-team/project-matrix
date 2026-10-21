# Project Matrix OpenShift installation package

This package installs the first horizontal control-plane slice:

```text
LayerDeployment CRD -> Project Matrix controller -> Gatekeeper Job
                                      ^
OpenShift AI Dashboard -> dashboard BFF --+
```

It does not install or replace OpenShift AI, Service Mesh, RHCL, Authorino,
Limitador, MCP Lifecycle, or MaaS operators. Those remain explicit platform
dependencies owned by their respective Red Hat AI: Agentic Strategy layers.
When the Gatekeeper profile enables DNS management, the executor reconciles only
the exact Gateway hostname advertised by the existing MCP Gateway through the
OpenShift ingress DNS operator. It does not modify the cluster-wide wildcard.

## Prerequisites

Project Matrix is one shipped artifact with two selectable operating lanes. The
Production lane is the default. The Preview lane is an explicitly disclosed,
isolated innovation lane for technology/developer-preview evaluation; it is
not a separate product. See `RELEASE_LANES.md` for the support boundary and
acceptance criteria.

1. OpenShift AI is already installed.
2. The reviewed Gatekeeper runner policy is acceptable for the target cluster.
3. The controller, Gatekeeper, Dashboard BFF, and combined Dashboard host images
   are mirrored to an approved registry and pinned by the release process.
   Current immutable Quay references are recorded in `IMAGE_RELEASE_LOCK.md`.
4. `controller-config.yaml` contains the immutable Gatekeeper executor image
   digest. If it is empty, the controller intentionally remains plan-only.
5. The OpenShift AI Dashboard host has the Project Matrix federated package
   registered at build time. Current Dashboard discovery is monorepo-based;
   applying this package alone cannot add a new navigation entry.

Before host registration, validate the independent package and its built
federated artifacts:

```bash
bash ui/validate-host-integration.sh --require-build
```

The host release then consumes `@odh-dashboard/project-matrix` from its normal
`packages/*` workspace and selects it through the Dashboard plugin discovery
contract. This is the only step that changes the Dashboard host image; it does
not move Project Matrix into another repository.

For live evaluation, `dashboard-host-buildconfig.yaml` defines an isolated
native OpenShift build in `project-matrix-build`. It is intentionally excluded
from the shipped Kustomize package and does not replace the operator-managed
Dashboard deployment. The resulting combined host image is promoted and
digest-locked separately from the Project Matrix control-plane images.

That build is a maintainer/release activity, not an end-user installation
step. The customer-facing release contains prebuilt digest-locked images and
requires no source upload, compiler, Node package installation, or local
runtime. The release performance and image-boundary contract is recorded in
[`RELEASE_PERFORMANCE.md`](RELEASE_PERFORMANCE.md).

## Install

From the Project Matrix root, after replacing the example image references and
promoting the manifests through the normal release process:

```bash
oc apply -k .
```

The aggregate `kustomization.yaml` lives at the Project Matrix root so it can
include both the controller package and the reviewed Gatekeeper platform policy.
There is intentionally no standalone `oc apply -k deploy` entrypoint; doing so
would split the CRD, preview namespace, and runner policy from the controller
release.

Apply the package as a platform administrator. The dashboard BFF has only
`get`, `create`, and `patch` access to the fixed
`matrix-system/gatekeeper` LayerDeployment through its reviewed Role. The
controller has only the API permissions needed to reconcile LayerDeployment
status, plan ConfigMaps, Gatekeeper Jobs, and leader-election leases.

## Verify

Run the read-only baseline check before any installation attempt:

```bash
PROJECT_MATRIX_EXPECTED_SERVER=https://api.<cluster-domain>:6443 \
  ./deploy/verify-cluster.sh
```

It verifies authentication, target-server identity, OpenShift version,
ClusterOperator health, and DataScienceCluster presence. It does not mutate
the cluster.

After installation:

```bash
oc get deployment -n matrix-system project-matrix-controller project-matrix-dashboard-bff
oc get layerdeployment -n matrix-system gatekeeper
oc logs deployment/project-matrix-controller -n matrix-system
```

The Dashboard BFF and combined Dashboard host images must be deployed through
the reviewed OpenShift AI Dashboard host release before this package is called
production-ready. The current immutable Quay references are recorded in
`IMAGE_RELEASE_LOCK.md`; the operator-managed production Dashboard is not
modified by the Project Matrix install package.

### Opt-in combined Dashboard host evaluation

The shipped package does not replace the operator-managed Dashboard. To test
the combined host image on the live cluster, run the explicit evaluation path:

```bash
./deploy/deploy-dashboard-host-evaluation.sh
```

It creates only `project-matrix-dashboard-eval` resources, reuses the existing
Red Hat Dashboard sidecars and configuration, and uses a re-encrypted Route.
The direct Route requires an OpenShift bearer token; the normal `rh-ai`
entrypoint remains the platform OAuth-fronted production surface. The script
uses the cluster-local immutable image by default and can be pointed at an
approved mirror with `PROJECT_MATRIX_DASHBOARD_HOST_IMAGE`.

To add the browser/OAuth evaluation front door, run the separate opt-in
authenticator step:

```bash
./deploy/deploy-dashboard-host-auth-evaluation.sh
```

It creates a dedicated OpenShift OAuthClient and Red Hat `kube-auth-proxy`
copy for the evaluation host. It does not modify the production
`data-science` OAuthClient or `GatewayConfig`. The evaluation proxy uses a
dedicated NetworkPolicy and service-account path; the normal `rh-ai`
entrypoint remains the production Dashboard surface.

The controller will not execute Gatekeeper until
`GATEKEEPER_EXECUTOR_IMAGE` is populated with a promoted immutable digest. This
is deliberate: an unpinned or missing executor must never become an implicit
production dependency.

## Repeatable teardown and reinstall

To remove only the Project Matrix-owned control plane while preserving the
Red Hat-managed Gateway:

```bash
PROJECT_MATRIX_CONFIRM_TEARDOWN=1 ./deploy/teardown.sh
oc apply -k .
```

The teardown script refuses to run without the explicit confirmation variable,
checks that `matrix-system` and `mcp-gateway-preview` disappear, and verifies
that the identity of `mcp-gateway-system/Gateway/mcp-gateway` is unchanged.

The combined Dashboard host and browser/OAuth evaluation resources are
deliberately outside the aggregate Kustomize package. Include them explicitly
when testing a full evaluation reinstall:

```bash
PROJECT_MATRIX_CONFIRM_TEARDOWN=1 ./deploy/teardown.sh \
  --dashboard-auth-evaluation --dashboard-evaluation
oc apply -k .
./deploy/deploy-dashboard-host-evaluation.sh
./deploy/deploy-dashboard-host-auth-evaluation.sh
```

These flags delete only the named `project-matrix-dashboard-eval` resources,
their dedicated OAuthClient and proxy, and the image-puller RoleBinding. They
never target the operator-managed Dashboard, the production `data-science`
OAuthClient, `GatewayConfig`, or the Red Hat MCP Gateway.
