# Native OpenShift AI Dashboard host integration

Project Matrix is intended to appear on the native OpenShift AI landing page,
not as a second customer-facing Dashboard. The current OpenShift AI Dashboard
workspace used for live validation is `/Users/geraldtrotman/Virtualenvs/odh-dashboard`.

The host-side landing card is implemented at:

```text
frontend/src/pages/home/ProjectMatrixHomeCard.tsx
```

and is rendered by `frontend/src/pages/home/Home.tsx`. The host card has one
responsibility: present **Red Hat AI: Agentic Strategy** and open
`/project-matrix`. The federated Project Matrix package owns The Construct,
layer status, the Production/Preview toggle, and the constrained BFF request.

This boundary is intentional. The current Dashboard extension contract
supports navigation, routes, and module federation but does not expose a
generic landing-page-card extension point.

The compatible host workspace builds successfully in the live OpenShift
cluster with `BUILD_MODE=RHOAI`. The OpenShift AI Dashboard operator does not
expose a custom dashboard-image field and reconciles direct deployment image
overrides back to the Red Hat image. Therefore the card becomes customer
visible only when the host change is accepted through the normal Dashboard
release/packaging path. The Project Matrix installer must not patch the
operator-managed Dashboard out of band.
