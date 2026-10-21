# Gatekeeper live Gateway and authentication evidence — 2026-10-19

Layer: Gateway — Project Matrix: Gatekeeper  
Cluster: target OpenShift AI validation instance  
OpenShift AI: 3.5.0  
MCP Gateway Operator: `mcp-gateway.v0.7.1`, `preview` channel

## Remediations applied

- Preserved the Aramco/reference same-port topology: public `mcp` and internal
  `mcps` listeners are both HTTP on port `8443`.
- Moved public TLS to the OpenShift edge Route
  `mcp-gateway.apps.ocp-gb.ibm.redhataicatalyst.com`, with redirect enabled.
- Corrected MCP backend HTTPRoutes to `*.mcp.local` and `sectionName: mcps`.
- Reconciled the public DNSRecord to the OpenShift router load balancer.
- Applied `security.opendatahub.io/authorino-tls-bootstrap=true` and
  `opendatahub.io/managed=false` to the custom Gateway. OpenShift AI created
  the operator-owned `mcp-gateway-authn-ssl` EnvoyFilter with the service-CA
  TLS transport socket for Authorino.
- Removed exploratory, non-operator-owned TLS EnvoyFilters after the Red Hat
  OpenShift AI integration point became available.

## Runtime proof

The public edge now returns the required fail-closed behavior:

```text
unauthenticated POST /mcp: 401 Unauthorized
WWW-Authenticate: Bearer
x-ext-auth-reason: credential not found
```

Using a short-lived in-cluster service-account token, the public MCP endpoint
returned:

```text
initialize: 200; MCP session present
tools/list: 200; 46 tools returned
tools/call namespaces_list: 200; isError=false
```

No bearer token or response body was retained in this evidence file.

## Gatekeeper gate audit

- Innovation preflight: `failures=0`, `warnings=1` (Technology Preview).
- Production preflight: `failures=1`, specifically the preview-only MCP Gateway
  channel. The production profile now selects OpenShift TokenReview as the
  Red Hat-native default, and the active policy matches that mode. All
  infrastructure, edge, ingress, DNS, isolation, and same-port topology checks
  passed.
- Native OIDC is an explicit alternate mode. After the Authorino service-CA
  TLS bootstrap repair, a controlled Keycloak-policy regression probe produced
  `Accepted=True`, `Enforced=True`, and unauthenticated HTTP `401`. The earlier
  HTTP `500` was from the pre-TLS-bootstrap state and is no longer current.
  Positive authenticated OIDC still requires an approved short-lived credential,
  and the separate `mcps` listener authorization path remains to be qualified.

## Boundary

This closes the installed-release OpenShift TokenReview/AuthPolicy and live
MCP protocol gates. It does not convert the MCP Gateway Technology Preview
into Red Hat-supported software. Native OIDC remains a separate customer-
identity qualification gate: the corrected policy now returns the required
unauthenticated HTTP 401, but a positive authenticated OIDC request and the
separate `mcps` listener authorization path still require approved validation.
A supported channel or time-bounded approved exception is the remaining
Production-lane support blocker for either authentication mode.

## References

- [OpenShift AI 3.5 Technology Preview release notes](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.5/html/release_notes/technology-preview-features_relnotes)
- [OpenShift AI / MaaS Authorino TLS configuration](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.5/pdf/govern_llm_access_with_models-as-a-service/Red_Hat_OpenShift_AI_Self-Managed-3.5-Govern_LLM_access_with_Models-as-a-Service-en-US.pdf)
- [Red Hat Connectivity Link MCP Gateway installation](https://docs.redhat.com/en/documentation/red_hat_connectivity_link/1.4/html/install_the_mcp_gateway/mcp-gateway-install)
- [Kuadrant MCP Gateway listener and router topology](https://docs.kuadrant.io/latest/mcp-gateway/docs/guides/configure-mcp-gateway-listener-and-router/)
