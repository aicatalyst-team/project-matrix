#!/usr/bin/env bash
# Read-only OpenShift AI baseline verification for Project Matrix.
# This script never creates, patches, deletes, or applies cluster resources.
set -uo pipefail

EXPECTED_SERVER="${PROJECT_MATRIX_EXPECTED_SERVER:-}"
failures=0
warnings=0

if ! command -v oc >/dev/null 2>&1; then
  echo "FAIL: oc is required" >&2
  exit 2
fi

pass() { printf 'PASS: %s\n' "$*"; }
warn() { warnings=$((warnings + 1)); printf 'WARN: %s\n' "$*"; }
fail() { failures=$((failures + 1)); printf 'FAIL: %s\n' "$*"; }

identity="$(oc whoami 2>/dev/null)" || identity=""
server="$(oc whoami --show-server 2>/dev/null)" || server=""
if [[ -z "${identity}" || -z "${server}" ]]; then
  fail "the current oc context is not authenticated or reachable"
else
  pass "authenticated as ${identity}"
  pass "connected to ${server}"
fi

if [[ -n "${EXPECTED_SERVER}" && "${server}" != "${EXPECTED_SERVER}" ]]; then
  fail "connected server does not match ${EXPECTED_SERVER}"
fi

cluster_version="$(oc get clusterversion version -o jsonpath='{.status.desired.version}' 2>/dev/null)" || cluster_version=""
if [[ -n "${cluster_version}" ]]; then
  pass "OpenShift version ${cluster_version}"
else
  fail "OpenShift ClusterVersion is unavailable"
fi

operator_json="$(oc get clusteroperators.config.openshift.io -o json 2>/dev/null)" || operator_json=""
if [[ -z "${operator_json}" ]]; then
  fail "ClusterOperator inventory is unavailable"
elif command -v jq >/dev/null 2>&1; then
  degraded="$(jq '[.items[] | select(any(.status.conditions[]?; .type == "Degraded" and .status == "True"))] | length' <<<"${operator_json}")"
  progressing="$(jq '[.items[] | select(any(.status.conditions[]?; .type == "Progressing" and .status == "True"))] | length' <<<"${operator_json}")"
  unavailable="$(jq '[.items[] | select(any(.status.conditions[]?; .type == "Available" and .status != "True"))] | length' <<<"${operator_json}")"
  if [[ "${degraded}" == "0" && "${unavailable}" == "0" ]]; then
    pass "all ClusterOperators are available and non-degraded"
  else
    fail "ClusterOperators degraded=${degraded}, unavailable=${unavailable}"
  fi
  if [[ "${progressing}" != "0" ]]; then
    warn "${progressing} ClusterOperator(s) are progressing"
  fi
else
  warn "jq is unavailable; ClusterOperator condition details were not evaluated"
fi

dsc_names="$(oc get datasciencecluster -A -o name 2>/dev/null)" || dsc_names=""
if [[ -z "${dsc_names}" ]]; then
  # Keep compatibility with clusters that expose the plural discovery name.
  dsc_names="$(oc get datascienceclusters.dsc.opendatahub.io -A -o name 2>/dev/null)" || dsc_names=""
fi
if [[ -n "${dsc_names}" ]]; then
  pass "OpenShift AI DataScienceCluster resource exists: ${dsc_names//$'\n'/, }"
  if command -v jq >/dev/null 2>&1; then
    dsc_name="$(printf '%s\n' "${dsc_names}" | head -n 1 | awk -F/ '{print $NF}')"
    dsc_json="$(oc get datasciencecluster "${dsc_name}" -o json 2>/dev/null)" || dsc_json=""
    dsc_phase="$(jq -r '.status.phase // ""' <<<"${dsc_json}")"
    dsc_ready="$(jq -r 'any(.status.conditions[]?; .type == "Ready" and .status == "True")' <<<"${dsc_json}")"
    if [[ "${dsc_phase}" == "Ready" && "${dsc_ready}" == "true" ]]; then
      pass "DataScienceCluster/${dsc_name}: Ready"
    else
      fail "DataScienceCluster/${dsc_name} is not Ready (phase=${dsc_phase:-unknown}, ready=${dsc_ready})"
    fi
  else
    warn "jq is unavailable; DataScienceCluster readiness condition was not evaluated"
  fi
else
  fail "no OpenShift AI DataScienceCluster resource was found"
fi

pass "DataScienceCluster is the OpenShift AI installation readiness source"

if (( failures > 0 )); then
  printf 'RESULT: NOT_READY failures=%d warnings=%d\n' "${failures}" "${warnings}"
  exit 1
fi
printf 'RESULT: BASELINE_READY failures=0 warnings=%d\n' "${warnings}"
