#!/usr/bin/env bash
# Project Matrix Gatekeeper: RHCL prerequisite gate.
#
# Read-only by design. This script never changes a Subscription, OperatorGroup,
# InstallPlan, CSV, namespace, or catalog. It establishes whether the cluster
# can safely host the pinned upstream MCP Gateway preview.

set -euo pipefail

RHCL_PACKAGE_NAME="${RHCL_PACKAGE_NAME:-rhcl-operator}"
RHCL_MIN_VERSION="${RHCL_MIN_VERSION:-1.5.0}"
RHCL_OPERATOR_NAMESPACE="${RHCL_OPERATOR_NAMESPACE:-openshift-operators}"
RHCL_BROKEN_NAMESPACE="${RHCL_BROKEN_NAMESPACE:-mcp-gateway-system}"
RHCL_CATALOG_NAMESPACE="${RHCL_CATALOG_NAMESPACE:-openshift-marketplace}"

command -v oc >/dev/null 2>&1 || { echo "FAIL: oc is required" >&2; exit 2; }
command -v jq >/dev/null 2>&1 || { echo "FAIL: jq is required" >&2; exit 2; }
oc whoami >/dev/null 2>&1 || { echo "FAIL: authenticate with oc first" >&2; exit 2; }

version_at_least() {
  python3 - "$1" "$2" <<'PY'
import sys
def version(value):
    return tuple(int(part) for part in value.split('.')[:3])
try:
    raise SystemExit(0 if version(sys.argv[1]) >= version(sys.argv[2]) else 1)
except (ValueError, IndexError):
    raise SystemExit(1)
PY
}

failures=0
catalog_json="$(oc get packagemanifest "${RHCL_PACKAGE_NAME}" -n "${RHCL_CATALOG_NAMESPACE}" -o json 2>/dev/null || echo '{}')"
if [[ "$(jq -r '.metadata.name // empty' <<<"${catalog_json}")" != "${RHCL_PACKAGE_NAME}" ]]; then
  echo "FAIL: RHCL package ${RHCL_PACKAGE_NAME} is not present in ${RHCL_CATALOG_NAMESPACE}"
  exit 1
fi

available_channels="$(jq -r --arg min "${RHCL_MIN_VERSION}" '
  [.status.channels[]? | {name, currentCSV}] | map(select(.currentCSV != null)) |
  .[] | "\(.name) -> \(.currentCSV)"' <<<"${catalog_json}")"
echo "RHCL catalog channels:"
if [[ -n "${available_channels}" ]]; then
  while IFS= read -r channel; do echo "  ${channel}"; done <<<"${available_channels}"
else
  echo "  none"
fi

candidate_csvs="$(jq -r --arg min "${RHCL_MIN_VERSION}" '
  [.status.channels[]? | .currentCSV] | map(select(. != null)) | .[]' <<<"${catalog_json}")"
approved_candidate=""
if [[ -n "${candidate_csvs}" ]]; then
  while IFS= read -r csv_name; do
    [[ -n "${csv_name}" ]] || continue
    csv_json="$(oc get csv "${csv_name}" -n "${RHCL_OPERATOR_NAMESPACE}" -o json 2>/dev/null || echo '{}')"
    csv_version="$(jq -r '.spec.version // empty' <<<"${csv_json}")"
    if [[ -n "${csv_version}" ]] && version_at_least "${csv_version}" "${RHCL_MIN_VERSION}"; then
      approved_candidate="${csv_name}"
      break
    fi
  done <<<"${candidate_csvs}"
fi

if [[ -n "${approved_candidate}" ]]; then
  echo "PASS: RHCL ${approved_candidate} is available as an approved catalog candidate"
else
  echo "FAIL: RHCL ${RHCL_MIN_VERSION}+ is not available in the cluster OLM catalog"
  echo "      An approved Red Hat catalog/channel update is required before upstream preview installation"
  failures=$((failures + 1))
fi

global_subscription="$(oc get subscription "${RHCL_PACKAGE_NAME}" -n "${RHCL_OPERATOR_NAMESPACE}" -o json 2>/dev/null || echo '{}')"
global_installed="$(jq -r '.status.installedCSV // empty' <<<"${global_subscription}")"
if [[ -z "${global_installed}" ]]; then
  echo "FAIL: no installed RHCL CSV is recorded in ${RHCL_OPERATOR_NAMESPACE}"
  failures=$((failures + 1))
else
  global_csv="$(oc get csv "${global_installed}" -n "${RHCL_OPERATOR_NAMESPACE}" -o json 2>/dev/null || echo '{}')"
  global_version="$(jq -r '.spec.version // empty' <<<"${global_csv}")"
  global_phase="$(jq -r '.status.phase // empty' <<<"${global_csv}")"
  global_reason="$(jq -r '.status.reason // empty' <<<"${global_csv}")"
  global_operator_group="$(jq -r '.metadata.annotations["olm.operatorGroup"] // empty' <<<"${global_csv}")"
  if [[ "${global_phase}" == "Succeeded" ]]; then
    echo "PASS: cluster-wide RHCL CSV ${global_installed} (${global_version}) is Succeeded via ${global_operator_group}"
  else
    echo "FAIL: cluster-wide RHCL CSV ${global_installed} is ${global_phase:-Unknown}/${global_reason:-Unknown}"
    failures=$((failures + 1))
  fi
fi

broken_subscriptions="$(oc get subscriptions.operators.coreos.com -n "${RHCL_BROKEN_NAMESPACE}" -o json 2>/dev/null |
  jq -r --arg package "${RHCL_PACKAGE_NAME}" '[.items[]? | select(.spec.name == $package) | .metadata.name] | .[]' || true)"
if [[ -n "${broken_subscriptions}" ]]; then
  echo "FAIL: duplicate namespace-scoped RHCL subscription(s) in ${RHCL_BROKEN_NAMESPACE}:"
  while IFS= read -r name; do echo "      ${name}"; done <<<"${broken_subscriptions}"
  echo "      RHCL is AllNamespaces-only; platform owner must remove the duplicate through the approved OLM change path"
  failures=$((failures + 1))
else
  echo "PASS: no duplicate namespace-scoped RHCL subscription in ${RHCL_BROKEN_NAMESPACE}"
fi

stale_csvs="$(oc get csv -n "${RHCL_BROKEN_NAMESPACE}" -o json 2>/dev/null |
  jq -r --arg package "${RHCL_PACKAGE_NAME}" '[.items[]? | select((.metadata.name | startswith($package + ".")) and (.status.phase != "Succeeded")) | "\(.metadata.name) [\(.status.phase // "Unknown")/\(.status.reason // "Unknown")]" ] | .[]' || true)"
if [[ -n "${stale_csvs}" ]]; then
  echo "FAIL: stale non-Succeeded RHCL CSV(s) remain in ${RHCL_BROKEN_NAMESPACE}:"
  while IFS= read -r csv; do echo "      ${csv}"; done <<<"${stale_csvs}"
  echo "      Platform owner must remove only these failed remnants after confirming the global RHCL CSV remains healthy"
  failures=$((failures + 1))
else
  echo "PASS: no stale non-Succeeded RHCL CSV in ${RHCL_BROKEN_NAMESPACE}"
fi

if (( failures > 0 )); then
  echo "RHCL readiness: BLOCKED (${failures} gate failure(s))"
  exit 1
fi
echo "RHCL readiness: READY"
