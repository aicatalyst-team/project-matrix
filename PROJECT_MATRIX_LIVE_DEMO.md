# Project Matrix live demo and acceptance plan

This is the current live-cluster handoff for demonstrating the Red Hat AI:
Agentic Strategy horizontal one-click experience.

## Baseline already validated

The native OpenShift AI Dashboard landing page for this cluster is:

`https://rh-ai.apps.ocp-gb.ibm.redhataicatalyst.com/`

The operator-managed `rhods-dashboard` route redirects there. The OpenShift
Console URL is the cluster administration surface; it is not the OpenShift AI
Dashboard landing page.

The provided OpenShift AI instance currently passes the read-only baseline:

- OpenShift `4.21.8`;
- all ClusterOperators available and non-degraded;
- the OpenShift AI `DataScienceCluster` is `Ready`;
- the Project Matrix control-plane design is source-validated; and
- the isolated Dashboard/OAuth evaluation path is healthy, including browser
  redirect and token-authenticated `/api/health`.

The repaired wildcard certificate is valid for the Console, OpenShift OAuth,
and evaluation Dashboard hostnames.

## Source release now completed

The source tree has been migrated to the Project Matrix convention:

- project directory: `/Users/geraldtrotman/Virtualenvs/project-matrix`;
- API group: `project-matrix.redhat.com`;
- control-plane namespace: `matrix-system`;
- Gateway codename: `Gatekeeper`;
- Dashboard remote: `projectMatrix`;
- Dashboard route contract: `/project-matrix/api`;
- executor directory and command: `gatekeeper/gatekeeper.sh`; and
- Matrix visual language: The Construct, The Red Path, and The Blue Path.

The following checks pass locally:

```bash
cd /Users/geraldtrotman/Virtualenvs/project-matrix
gatekeeper/profiles/validate-catalog.sh
(cd controller && go test ./...)
(cd ui/frontend && npm run type-check && npm run build)
ui/validate-host-integration.sh --require-build
oc kustomize . >/tmp/project-matrix-rendered.yaml
```

## What can be demonstrated immediately

1. Run `deploy/verify-cluster.sh` against the live API.
2. Open the existing isolated Dashboard evaluation route and validate the
   repaired OpenShift OAuth redirect.
3. Use the existing token-authenticated health path to demonstrate the host
   and auth boundary.
4. Run the read-only RHCL gate:

   ```bash
   RHCL_MIN_VERSION=1.5.0 bash gatekeeper/rhcl/check-readiness.sh
   ```

5. Run the source-level Gateway/Aramco conformance and evidence workflow after
   supplying only the target endpoint and a short-lived credential.

The Matrix controller, Dashboard BFF, CRD, and Gatekeeper executor are now
installed in `matrix-system`. The first BFF one-click request created
`matrix-system/gatekeeper` as `Gateway / Gatekeeper / Production`; the
controller ran the real preflight and placed it in `Degraded` with six explicit
failures, then skipped installation/evaluation. This confirms fail-closed
behavior rather than a false-ready demo.

The renamed combined Dashboard host is deployed in the isolated Matrix
evaluation copy, with dependency caches and unrelated source excluded from the
maintainer-only build upload. Its dedicated OAuth front door is healthy and
the browser route returns the expected external OpenShift OAuth redirect.

The current isolated UI surface is a Dashboard navigation entry under
**Agentic Platform → Red Hat AI: Agentic Strategy**. The first-party homepage
card is implemented in the compatible Dashboard host source and the corrected
host image builds successfully, but the live operator-managed Dashboard still
serves the Red Hat image. The Dashboard operator reconciles any direct image
override back to its Red Hat digest, so the card cannot be claimed live until
the Project Matrix host change is accepted through the normal Dashboard
release/packaging path.

The intended production journey is to make **Red Hat AI: Agentic Strategy** a
first-party tile on this native landing page. Selecting it opens **The
Construct**, where the official horizontal layers are represented as Matrix
tiles: The Source, The One, The Architect, The Keymaker, The Gatekeeper,
Trinity, The Oracle, and Zion. The Gatekeeper tile is the first live one-click
surface, with The Red Path as the default and The Blue Path as an explicit
toggle. This remains one Dashboard host experience, not a separate product.

This build optimization is not part of the end-user experience. A customer
pulls the promoted digest and applies the release package; the customer never
runs `oc start-build`, uploads the Dashboard workspace, runs `npm install`, or
compiles Project Matrix locally. See
[`deploy/RELEASE_PERFORMANCE.md`](deploy/RELEASE_PERFORMANCE.md).

## Remaining live actions

1. Open `https://project-matrix-dashboard-eval.apps.ocp-gb.ibm.redhataicatalyst.com`
   and sign in through OpenShift OAuth; this remains the browser evaluation
   path while the operator-managed host release is pending.
2. Exercise the Dashboard click for Gateway / The Gatekeeper on The Red Path,
   then explicitly switch to The Blue Path and capture status/evidence.
3. Exercise the opt-in teardown/reinstall flags and verify the Red Hat Gateway
   identity remains unchanged.
4. Triage the combined host dependency audit before any production Dashboard
   host claim.

## Release gates that remain intentionally open

- RHCL `1.5.0+` is not available in the live catalog; the pinned upstream
  Innovation path must remain fail-closed.
- The installed MCP Gateway remains a Technology Preview dependency; Project
  Matrix cannot claim Red Hat Production support without a supported channel or
  approved exception.
- Positive RHCL-documented OIDC and authenticated internal `mcps` authorization
  still require qualification.
- The combined Dashboard host dependency-audit findings require security
  triage.
- The operator-managed Dashboard homepage tile remains a host-release
  integration item. Direct deployment image overrides are reconciled away and
  are not part of the customer installer.
