# Project Matrix evidence

Evidence in this directory is non-secret output from read-only validation or
explicitly approved evaluation runs. Bearer tokens, Kubernetes Secrets, and
credential material must never be copied here.

## 2026-10-17 live OpenShift AI validation

The reports under `live/20261017/` contain:

- innovation preflight: zero failures, three warnings;
- production preflight: failed closed on ingress degradation, preview Gateway
  dependency, and missing OIDC issuer;
- innovation structural validation: zero failures, with public MCP edge HTTP
  `503` recorded as a warning because the innovation lane remains advisory;
- read-only Aramock-derived conformance: zero failures, advisory because the
  fixture is not installed.

The reports identify the target cluster only by its API server and support
diagnosis; they do not constitute a production-support claim.
