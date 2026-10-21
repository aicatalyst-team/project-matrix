#!/usr/bin/env bash
# Remove only the Project Matrix control-plane package.
#
# This deliberately deletes the rendered Project Matrix package, including its
# isolated preview namespace, but never targets mcp-gateway-system or any
# Red Hat-managed operator/Gateway resource.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

remove_dashboard_evaluation=0
remove_dashboard_auth_evaluation=0

for arg in "$@"; do
  case "${arg}" in
    --dashboard-evaluation)
      remove_dashboard_evaluation=1
      ;;
    --dashboard-auth-evaluation)
      remove_dashboard_auth_evaluation=1
      ;;
    *)
      echo "Unknown teardown option: ${arg}" >&2
      echo "Usage: PROJECT_MATRIX_CONFIRM_TEARDOWN=1 $0 [--dashboard-evaluation] [--dashboard-auth-evaluation]" >&2
      exit 2
      ;;
  esac
done

if [[ "${PROJECT_MATRIX_CONFIRM_TEARDOWN:-0}" != "1" ]]; then
  echo "Refusing teardown: set PROJECT_MATRIX_CONFIRM_TEARDOWN=1 explicitly." >&2
  echo "Only Project Matrix resources rendered by ${ROOT}/kustomization.yaml will be removed." >&2
  exit 2
fi

command -v oc >/dev/null 2>&1 || { echo "oc is required" >&2; exit 2; }
oc whoami >/dev/null 2>&1 || { echo "authenticate with oc before teardown" >&2; exit 2; }

if [[ "${remove_dashboard_auth_evaluation}" == "1" ]]; then
  echo "removing the isolated Dashboard OAuth evaluation resources"
  oc delete route/project-matrix-dashboard-eval-auth \
    service/project-matrix-dashboard-eval-auth \
    deployment/project-matrix-dashboard-eval-auth \
    secret/project-matrix-dashboard-eval-auth-creds \
    secret/project-matrix-dashboard-eval-auth-tls \
    -n openshift-ingress --ignore-not-found=true
  oc delete oauthclient/project-matrix-dashboard-eval --ignore-not-found=true
  oc delete service/project-matrix-dashboard-eval-auth-upstream \
    networkpolicy/project-matrix-dashboard-eval-auth-upstream \
    -n redhat-ods-applications --ignore-not-found=true
fi

if [[ "${remove_dashboard_evaluation}" == "1" ]]; then
  echo "removing the isolated combined Dashboard host evaluation resources"
  oc delete route/project-matrix-dashboard-eval \
    service/project-matrix-dashboard-eval \
    deployment/project-matrix-dashboard-eval \
    -n redhat-ods-applications --ignore-not-found=true
  oc delete rolebinding/project-matrix-dashboard-image-puller \
    -n project-matrix-build --ignore-not-found=true
fi

redhat_gateway_before="$(oc get gateway mcp-gateway -n mcp-gateway-system \
  -o jsonpath='{.metadata.uid}' 2>/dev/null || true)"

oc delete -k "${ROOT}" --ignore-not-found=true

for namespace in matrix-system mcp-gateway-preview; do
  namespace_removed=0
  for attempt in {1..60}; do
    if ! oc get namespace "${namespace}" >/dev/null 2>&1; then
      namespace_removed=1
      break
    fi
    phase="$(oc get namespace "${namespace}" -o jsonpath='{.status.phase}' 2>/dev/null || true)"
    echo "waiting for Project Matrix namespace ${namespace} to finish deletion (${phase:-unknown}, ${attempt}/60)"
    sleep 2
  done
  if [[ "${namespace_removed}" != "1" ]]; then
    echo "teardown incomplete: namespace ${namespace} still exists after 120 seconds" >&2
    exit 1
  fi
done

if [[ -n "${redhat_gateway_before}" ]]; then
  redhat_gateway_after="$(oc get gateway mcp-gateway -n mcp-gateway-system \
    -o jsonpath='{.metadata.uid}' 2>/dev/null || true)"
  if [[ "${redhat_gateway_after}" != "${redhat_gateway_before}" ]]; then
    echo "safety check failed: Red Hat-managed Gateway identity changed" >&2
    exit 1
  fi
  echo "preserved Red Hat-managed Gateway mcp-gateway (${redhat_gateway_before})"
else
  echo "warning: mcp-gateway-system/Gateway mcp-gateway was not present before teardown" >&2
fi

echo "Project Matrix control plane removed; the Red Hat-managed Gateway was not targeted."
