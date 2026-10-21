# MCP Gateway release contract

Project Matrix has one preview lane: the pinned upstream Kuadrant MCP Gateway
release recorded in [`mcp-gateway.json`](./mcp-gateway.json). The live Red Hat
OLM package is the production-candidate compatibility baseline, not a second
preview implementation.

The preview installer is intentionally isolated by namespace and refuses to
run unless the cluster has the Connectivity Link baseline required by the
upstream OpenShift deployment. It does not approve an InstallPlan, replace a
Red Hat operator, or overwrite the live Gatekeeper Gateway.

The pinned source and chart were inspected from:

```text
https://github.com/Kuadrant/mcp-gateway @ v1.0.2
e48ae51cfa52a57f93f334bdadbe8ce58ef5a9f6
```

The OCI chart is pinned by digest in the release contract:

```text
sha256:97be2a4ba4daae5b5a8470074c414a94c02689d3e9c3910eaa098f6044e42eb3
```

That upstream release is an engineering reference for the innovation lane.
Its existence does not change the Red Hat support classification of MCP
Gateway in OpenShift AI or Connectivity Link.
