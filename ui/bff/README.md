# Project Matrix dashboard BFF contract

The dashboard extension must call a small, authenticated BFF rather than the
Kubernetes API directly. This keeps the browser free of cluster credentials
and makes the one-click action auditable.

## Routes

The federated frontend calls the browser-facing `/project-matrix/api` prefix.
The ODH Dashboard module proxy rewrites that prefix to `/api` when forwarding
to the BFF service. The BFF accepts both paths only at this transport
boundary; authorization, validation, and Kubernetes access are identical.

### `GET /project-matrix/api/v1/layerdeployments/gatekeeper`

The BFF reads only the platform-owned `gatekeeper` `LayerDeployment` from the
validated `matrix-system` namespace. It returns the OpenShift AI modular
architecture response envelope:

```json
{ "data": null }
```

for the initial state, or:

```json
{ "data": { "apiVersion": "project-matrix.redhat.com/v1alpha1", "kind": "LayerDeployment" } }
```

with the complete resource when it exists.

### `POST /project-matrix/api/v1/layerdeployments/gatekeeper`

The BFF accepts only the fixed Gatekeeper request shape documented in
`project-matrix/ui/README.md`. It must validate all of the following before
calling the Kubernetes API:

- namespace is exactly `matrix-system`;
- layer is `Gateway` and code name is `Gatekeeper`;
- mode is `Production` or `Preview`;
- profile is the mode-matched `gateway-production` or `gateway-evaluation`;
- desired state is `Enabled`; and
- coexistence is enabled with inactive-lane retention enabled.

The BFF should use an idempotent create-or-update operation and return the
resulting `LayerDeployment`, including its current `status`. It must not create
Jobs, patch operators, alter Gateway API ownership, or invoke Aramock setup
scripts.

## Authorization boundary

The BFF service account needs only the reviewed Project Matrix permissions to
read and create/update the `LayerDeployment` in `matrix-system`. The
controller service account retains the separate permissions required for
reconciliation and Gatekeeper execution. The dashboard extension itself should
receive no Kubernetes RBAC.

The reviewed starting manifest is `project-matrix/ui/bff/rbac.yaml`. The BFF
implementation is the `controller/cmd/bff` binary and the constrained handler
in `controller/bff/server.go`. Its default identity boundary requires the
dashboard reverse proxy to provide a non-empty `Authorization: Bearer ...`
header, matching the ODH Dashboard federated-module `authorize: true` proxy
behavior. Deployment-specific authentication must preserve that trusted-proxy
boundary rather than exposing the BFF directly to end users. Local development
may set `BFF_USER_HEADER=X-Forwarded-User` for the development proxy.

For production federation, the BFF can also serve the compiled remote assets
when `BFF_STATIC_DIR` is set. This allows the dashboard's module service and
its Project Matrix API proxy to use one reviewed Service endpoint on port 8082;
the local development frontend remains on port 9109.

