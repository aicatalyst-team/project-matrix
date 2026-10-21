# Gatekeeper Production exceptions

The Production lane does not silently convert Technology Preview software into
supported software. If a platform owner and Red Hat/customer governance group
explicitly authorize evaluation or operational use of a Preview dependency,
the exception must be supplied as a separate file through
`GATEKEEPER_SUPPORT_EXCEPTION_FILE`.

The file is evidence, not a Red Hat support entitlement. It must identify the
exact installed component, version, channel, approving authority, scope,
approval reference, and an expiration time. Gatekeeper matches the version and
channel discovered from OLM and rejects expired or incomplete exceptions.

Example shape:

```json
{
  "apiVersion": "project-matrix.redhat.com/v1alpha1",
  "kind": "GatekeeperProductionException",
  "component": "MCP Gateway Operator",
  "installedVersion": "0.7.1",
  "installedChannel": "preview",
  "decision": "accept-technology-preview",
  "approvalRef": "CHANGE-0000",
  "approvedBy": "platform-owner@example.com",
  "scope": "Gateway layer evaluation on the named OpenShift AI instance",
  "expiresAt": "2026-12-31T23:59:59Z"
}
```

Do not commit customer approvals, credentials, or exception files to the
repository. The report records only the approval reference, approver,
expiration, and SHA-256 digest. A valid exception changes the gate from
“unsupported and blocked” to “explicitly accepted under exception”; it does
not change Red Hat’s published Technology Preview support boundary.
