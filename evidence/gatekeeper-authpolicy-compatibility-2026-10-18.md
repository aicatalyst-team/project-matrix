# Gatekeeper OIDC AuthPolicy Compatibility Evidence

Date: 2026-10-18
Layer: Gateway — Project Matrix: Gatekeeper
Cluster: target OpenShift AI validation instance
Installed dependency: MCP Gateway Operator `mcp-gateway.v0.7.1`, `preview` channel

## Test

1. Applied the reviewed `mcp-auth-policy` targeting
   `Gateway/mcp-gateway`, listener `sectionName: mcp`.
2. Used the verified Keycloak issuer for token claim validation.
3. Used the cluster-local Keycloak JWKS endpoint for key retrieval.
4. Confirmed AuthPolicy conditions:
   - `Accepted=True`
   - `Enforced=True`
5. Sent an unauthenticated JSON-RPC `initialize` request to the public HTTPS
   MCP endpoint.

## Result

The edge returned HTTP `500`. The required unauthenticated response is HTTP
`401` with the OAuth `WWW-Authenticate` challenge. Removing only the temporary
AuthPolicy restored the endpoint to HTTP `200` after policy detachment.

## Decision

Do not claim native OIDC Gateway enforcement as Production-ready on this
installed release. Do not leave the failing policy applied. The Production
lane remains blocked until a supported release/channel or approved exception
and a compatible AuthPolicy data path are available. The Preview lane records
this as an explicit compatibility limitation.

## References

- Red Hat OpenShift AI 3.5 Technology Preview release notes:
  https://docs.redhat.com/de/documentation/red_hat_openshift_ai_self-managed/3.5/html/release_notes/technology-preview-features_relnotes
- MCP Gateway authorization guide:
  https://github.com/Kuadrant/mcp-gateway/blob/main/docs/guides/authorization.md
