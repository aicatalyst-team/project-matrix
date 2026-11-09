#!/usr/bin/env bash
set -euo pipefail

# One-time platform-admin bootstrap for the Project Matrix Gateway evaluator.
# The end user receives namespace-scoped MCPServer lifecycle access only. The
# dashboard service account remains responsible for ownership-scoped mutations.

namespace="${PROJECT_MATRIX_GATEWAY_NAMESPACE:-mcp-gateway-preview}"
user="${PROJECT_MATRIX_EVALUATOR_USER:-}"
group="${PROJECT_MATRIX_EVALUATOR_GROUP:-project-matrix-gateway-evaluators}"
role="project-matrix-gateway-installer-user"

usage() {
  cat <<'EOF'
Usage:
  grant-gateway-evaluator-access.sh [--namespace NAMESPACE] [--user USER | --group GROUP]

Environment equivalents:
  PROJECT_MATRIX_GATEWAY_NAMESPACE
  PROJECT_MATRIX_EVALUATOR_USER
  PROJECT_MATRIX_EVALUATOR_GROUP

The default binding target is the portable evaluator group
project-matrix-gateway-evaluators. Prefer a group in customer environments.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --namespace)
      [[ $# -ge 2 ]] || { usage >&2; exit 2; }
      namespace="$2"
      shift 2
      ;;
    --user)
      [[ $# -ge 2 ]] || { usage >&2; exit 2; }
      user="$2"
      group=""
      shift 2
      ;;
    --group)
      [[ $# -ge 2 ]] || { usage >&2; exit 2; }
      group="$2"
      user=""
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage >&2
      exit 2
      ;;
  esac
done

[[ -n "${user}" || -n "${group}" ]] || { usage >&2; exit 2; }
command -v oc >/dev/null 2>&1 || { echo "oc is required" >&2; exit 2; }
oc whoami >/dev/null 2>&1 || { echo "An authenticated oc session is required" >&2; exit 2; }

oc get namespace "${namespace}" >/dev/null
oc get role "${role}" -n "${namespace}" >/dev/null 2>&1 || oc create role "${role}" \
  --verb=get,list,create,patch,delete \
  --resource=mcpservers.mcp.x-k8s.io \
  -n "${namespace}" >/dev/null

binding="${role}-binding"
if [[ -n "${user}" ]]; then
  oc create rolebinding "${binding}" --role="${role}" --user="${user}" -n "${namespace}" >/dev/null 2>&1 || \
    oc set subject rolebinding "${binding}" "user:${user}" -n "${namespace}" >/dev/null
  echo "Bound ${role} to user ${user} in namespace ${namespace}."
else
  oc create rolebinding "${binding}" --role="${role}" --group="${group}" -n "${namespace}" >/dev/null 2>&1 || \
    oc set subject rolebinding "${binding}" "group:${group}" -n "${namespace}" >/dev/null
  echo "Bound ${role} to group ${group} in namespace ${namespace}."
fi

echo "Verify with: oc auth can-i create mcpservers.mcp.x-k8s.io -n ${namespace} --as=<evaluator>"
