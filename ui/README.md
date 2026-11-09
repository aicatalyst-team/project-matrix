# Project Matrix OpenShift AI dashboard extension

This is the dashboard-side entry point for Project Matrix's horizontal
one-click deployment model. It follows the Open Data Hub / OpenShift AI
module-federation shape used by the local OpenClaw extension, but it does not
reuse OpenClaw's installer lifecycle.

The user-facing destination is **Red Hat AI Stack**. Official Red Hat AI:
Agentic Strategy layer names remain primary; Matrix codenames provide the
secondary journey vocabulary. See `../PROJECT_MATRIX_CONVENTION.md` for the
canonical mapping.

The landing page shows the horizontal layers in architectural order. Each
available layer owns one guided install action and one truthful status stream.
The current first deliverable is Gateway / Gatekeeper. Its installer has one
primary action; the lane switch only selects the mode and does not submit until
the user presses that action:

```text
Use Innovation lane: OFF | ON
```

The control maps to the two supported Gatekeeper Gateway profiles:

| UI state | `LayerDeployment.spec.mode` | profile |
| --- | --- | --- |
| OFF | `Production` | `gateway-production` |
| ON | `Preview` | `gateway-evaluation` |

The extension sends an idempotent apply request to the dashboard BFF. The BFF
must authenticate the dashboard user, authorize the Project Matrix action, and
create or update the namespaced `LayerDeployment` named `gatekeeper` in the
platform-owned `matrix-system` namespace. It must not accept arbitrary
manifests, arbitrary profiles, or arbitrary namespaces from the browser.

Expected BFF endpoints:

```text
GET  /project-matrix/api/v1/layerdeployments/gatekeeper?namespace=matrix-system
POST /project-matrix/api/v1/layerdeployments/gatekeeper
```

The POST body is the constrained intent below. A successful response uses the
OpenShift AI modular-architecture response envelope (`{ "data": ... }`). A
missing deployment should be returned as `{ "data": null }` rather than a
browser-visible 404 so the UI can present the first-click state.

```json
{
  "namespace": "matrix-system",
  "spec": {
    "layer": "Gateway",
  "codeName": "Gatekeeper",
    "mode": "Production",
    "desiredState": "Enabled",
    "profile": "gateway-production",
    "coexistence": {
      "enabled": true,
      "retainInactiveLane": true
    }
  }
}
```

Customer-specific profiles are intentionally not accepted by this horizontal
endpoint. Saudi Aramco and Aramock-derived acceptance flows remain profile
sources and conformance evidence; they become explicit vertical/use-case
contracts after the horizontal Gateway layer is accepted.

The BFF is a transport and authorization boundary, not a second controller.
It should use the Kubernetes API to apply this single resource and return the
resource's current `status`. The Project Matrix controller owns all mutation
after that point, including conflict detection, execution Jobs, readiness, and
evidence references.

This source scaffold is wired into the compatible OpenShift AI Dashboard
workspace through the package's module-federation metadata. The BFF route,
feature registration, RBAC, and host build are validated on the live OpenShift
AI instance. The native host landing-card contract and its operator ownership
boundary are documented in `host-integration/README.md`.

## Dashboard host integration contract

The OpenShift AI Dashboard discovers federated extensions from workspace
packages that export `./extensions`. Project Matrix remains an independent
directory and package; it is consumed by the Dashboard build as
`@odh-dashboard/project-matrix`. The host-side integration is therefore a
build-time registration, not a runtime browser switch.

Validate the package and a completed remote build with:

```bash
bash ./validate-host-integration.sh --require-build

# Validate a build written to a disposable output directory
bash ./validate-host-integration.sh --require-build --dist-dir /tmp/project-matrix-dist
```

In the compatible OpenShift AI Dashboard workspace, make the package available
under its existing `packages/*` workspace (for example as
`packages/project-matrix`), install workspace dependencies, and build the host
with the package selected through the Dashboard's normal plugin discovery
(`PLUGIN_PACKAGES=@odh-dashboard/project-matrix` when using an explicit list).
The host will load `/projectMatrix/remoteEntry.js` and the extension export at
`projectMatrix/extensions`; its module-federation proxy routes the Dashboard
path `/project-matrix/api` to the `matrix-system/project-matrix-dashboard-bff`
Service on port 8082.

The validator and the standalone remote build are complete here. The combined
Dashboard image remains a host-release action because it changes the Dashboard
workspace/image, not the Project Matrix installation boundary. The standalone
`type-check` target likewise requires the host's actual `@odh-dashboard/*`
workspace packages; the remote production build is the authoritative artifact
check in this independent package. Production builds omit source maps by
default; set `SOURCE_MAPS=true` only for a diagnostic build.

## Local visual preview

After the frontend dependencies are installed, the first visual preview can be
run from this directory:

```bash
# One-time setup
cd project-matrix/ui/frontend
npm install
cd ..

# Terminal 1: use the current kubeconfig/oc context for the BFF
make dev-bff

# Terminal 2: start the federated frontend remote
make dev-frontend
```

Open `http://localhost:9109`. The local webpack proxy adds a development
identity header and forwards `/project-matrix/api` to the BFF on port 8082. The
BFF still requires a reachable Kubernetes API and the Project Matrix CRD; if
the `LayerDeployment` does not exist yet, the page should show the initial
“Deploy Gateway layer” state.

For the actual OpenShift AI Dashboard experience, install the package into the
ODH Dashboard workspace and use the module's federated route. The menu entry
will be **AI Stack → Red Hat AI Stack** and the page will render the Gateway
layer first. Project Matrix and The Construct remain internal implementation
codename vocabulary.

