#!/usr/bin/env bash
# Project Matrix Gatekeeper: install the single authoritative upstream preview.
#
# This is deliberately an explicit, isolated action. It never upgrades or
# replaces the Red Hat OLM-managed MCP Gateway in the live namespace.

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${HERE}/../.." && pwd)"
RELEASE_FILE="${ROOT}/gatekeeper/releases/mcp-gateway.json"
RHCL_READINESS="${ROOT}/gatekeeper/rhcl/check-readiness.sh"

command -v oc >/dev/null 2>&1 || { echo "oc is required" >&2; exit 2; }
command -v helm >/dev/null 2>&1 || { echo "helm is required" >&2; exit 2; }
oc whoami >/dev/null 2>&1 || { echo "authenticate with oc before installing the preview" >&2; exit 2; }
[[ -f "${RHCL_READINESS}" ]] || { echo "RHCL readiness gate is missing: ${RHCL_READINESS}" >&2; exit 2; }

PREVIEW_VERSION="$(jq -r '.previewLane.version' "${RELEASE_FILE}")"
PREVIEW_COMMIT="$(jq -r '.previewLane.commit' "${RELEASE_FILE}")"
PREVIEW_CHART="$(jq -r '.previewLane.chart' "${RELEASE_FILE}")"
PREVIEW_CHART_DIGEST="$(jq -r '.previewLane.chartDigest' "${RELEASE_FILE}")"
RHCL_MIN="$(jq -r '.previewLane.requiredConnectivityLink' "${RELEASE_FILE}" | sed 's/^>=//')"
MCP_GATEWAY_NAMESPACE="${MCP_GATEWAY_NAMESPACE:-mcp-gateway-preview}"
GATEWAY_NAMESPACE="${GATEWAY_NAMESPACE:-mcp-gateway-preview}"
GATEWAY_NAME="${GATEWAY_NAME:-mcp-gateway-preview}"
GATEWAY_CLASS_NAME="${GATEWAY_CLASS_NAME:-openshift-default}"
if [[ -z "${MCP_GATEWAY_HOST:-}" ]]; then
  MCP_GATEWAY_HOST="mcp-gateway-preview.apps.$(oc get dns cluster -o jsonpath='{.spec.baseDomain}')"
fi

if ! RHCL_MIN_VERSION="${RHCL_MIN}" bash "${RHCL_READINESS}"; then
  echo "Refusing preview install: RHCL readiness gate is blocked; upstream ${PREVIEW_VERSION} requires RHCL ${RHCL_MIN}+" >&2
  echo "No namespace, Helm release, operator, or Gateway resource was changed." >&2
  exit 1
fi

if [[ "${GATEKEEPER_CONFIRM_UPSTREAM_PREVIEW:-0}" != "1" ]]; then
  echo "Set GATEKEEPER_CONFIRM_UPSTREAM_PREVIEW=1 to install upstream MCP Gateway ${PREVIEW_VERSION} in ${MCP_GATEWAY_NAMESPACE}." >&2
  echo "This is an innovation preview only; the Red Hat-managed Gateway is not modified." >&2
  exit 2
fi

if ! oc get namespace "${MCP_GATEWAY_NAMESPACE}" >/dev/null 2>&1; then
  echo "Refusing preview install: namespace ${MCP_GATEWAY_NAMESPACE} is not pre-provisioned." >&2
  echo "Apply the Project Matrix platform package first; the executor does not create cluster-scoped namespaces." >&2
  exit 1
fi

helm upgrade --install "${GATEWAY_NAME}" \
  "${PREVIEW_CHART}@${PREVIEW_CHART_DIGEST}" \
  --namespace "${MCP_GATEWAY_NAMESPACE}" \
  --skip-crds \
  --set controller.enabled=false \
  --set gateway.create=true \
  --set gateway.name="${GATEWAY_NAME}" \
  --set gateway.namespace="${GATEWAY_NAMESPACE}" \
  --set gateway.publicHost="${MCP_GATEWAY_HOST}" \
  --set gateway.internalHostPattern='*.mcp.local' \
  --set gateway.gatewayClassName="${GATEWAY_CLASS_NAME}" \
  --set mcpGatewayExtension.create=true \
  --set mcpGatewayExtension.gatewayRef.name="${GATEWAY_NAME}" \
  --set mcpGatewayExtension.gatewayRef.namespace="${GATEWAY_NAMESPACE}" \
  --set mcpGatewayExtension.gatewayRef.sectionName=mcp

oc apply -f - <<YAML
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: ${GATEWAY_NAME}
  namespace: ${GATEWAY_NAMESPACE}
  labels:
    project-matrix.redhat.com/preview-source: upstream
    project-matrix.redhat.com/preview-version: "${PREVIEW_VERSION}"
    project-matrix.redhat.com/preview-commit: "${PREVIEW_COMMIT}"
spec:
  host: ${MCP_GATEWAY_HOST}
  to:
    kind: Service
    name: ${GATEWAY_NAME}-${GATEWAY_CLASS_NAME}
  port:
    targetPort: mcp
  tls:
    termination: edge
    insecureEdgeTerminationPolicy: Redirect
  wildcardPolicy: None
YAML

oc label gateway "${GATEWAY_NAME}" -n "${GATEWAY_NAMESPACE}" \
  project-matrix.redhat.com/preview-source=upstream \
  project-matrix.redhat.com/preview-version="${PREVIEW_VERSION}" \
  project-matrix.redhat.com/preview-commit="${PREVIEW_COMMIT}" \
  project-matrix.redhat.com/managed=true --overwrite

oc wait --for='jsonpath={.status.ingress[0].conditions[?(@.type=="Admitted")].status}=True' \
  "route/${GATEWAY_NAME}" -n "${GATEWAY_NAMESPACE}" --timeout=120s >/dev/null
oc wait --for=condition=Programmed "gateway/${GATEWAY_NAME}" -n "${GATEWAY_NAMESPACE}" --timeout=180s >/dev/null
oc wait --for=condition=Ready "mcpgatewayextension/${GATEWAY_NAME}-extension" -n "${MCP_GATEWAY_NAMESPACE}" --timeout=180s >/dev/null

echo "Installed isolated upstream MCP Gateway ${PREVIEW_VERSION} (${PREVIEW_COMMIT})"
echo "Gateway namespace: ${GATEWAY_NAMESPACE}"
echo "Public host: ${MCP_GATEWAY_HOST}"
echo "Red Hat OLM-managed MCP Gateway was not modified."
