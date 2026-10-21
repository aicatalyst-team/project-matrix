# Project Matrix release lanes

Project Matrix ships as one artifact and one installation package. The two
operating modes are selectable lanes inside that same release:

| UI mode | Default | Gateway dependency | What the release may claim |
| --- | --- | --- | --- |
| Production | Yes | Red Hat-managed, supported dependency only | Production support for the recorded release/configuration boundary |
| Preview | No | Isolated pinned upstream MCP Gateway release | Innovation/evaluation evidence only; Technology Preview or Developer Preview as disclosed by the dependency |

Preview does not mean a second product or a second installer. It changes the
mode of the same `LayerDeployment`, selects the isolated upstream namespace,
and preserves the Production lane's Red Hat-managed resources. The UI may
toggle between them only after the controller reports a terminal state.

The evaluation criteria are therefore additive to the shipped artifact:

1. Production mode must fail closed on unsupported Gateway dependencies and
   must not mutate a Red Hat-managed operator or Gateway outside the reviewed
   Project Matrix policy surface.
2. Preview mode must install only the pinned upstream release in
   `mcp-gateway-preview`, record its source/version/commit, and expose its
   support boundary in status and evidence.
3. Teardown must remove Project Matrix-owned resources and preserve the
   Red Hat-managed `mcp-gateway-system` Gateway.
4. Reinstall must render and apply the same package without hand-editing
   manifests or changing the selected lane contract.

The Preview lane is included for future-capability demos and customer
evaluation. It is never silently promoted to Production by an upgrade or by a
successful Preview execution.
