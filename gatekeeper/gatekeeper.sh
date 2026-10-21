#!/usr/bin/env bash
# Project Matrix: Gatekeeper — Gateway Layer Evaluation Kit.
#
# One tracked workflow from an existing OpenShift AI baseline:
#   preflight -> install -> validate -> evaluate -> diagnostics
#
# The script is intentionally dependency-aware. It never installs or removes
# cluster-wide operators implicitly. Production mode fails closed on degraded
# platform state or preview dependencies; innovation mode continues with those
# boundaries recorded in the evidence bundle.

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${HERE}/.." && pwd)"
ARAMCO_ROOT="${GATEKEEPER_ARAMCO_ROOT:-${HERE}/vendor/aramco-mcp-lifecycle}"
PROFILE_NAME="${GATEKEEPER_PROFILE_NAME:-production}"
PROFILE_FILE="${HERE}/profiles/${PROFILE_NAME}.env"
PROFILE_CATALOG="${HERE}/profiles/catalog.json"
RUN_ROOT="${GATEKEEPER_RUN_ROOT:-${ROOT}/.gatekeeper-runs}"
RUN_ID="$(date -u +%Y%m%dT%H%M%SZ)-$$"
RUN_DIR="${RUN_ROOT}/${RUN_ID}"
UPGRADE_BASELINE="${GATEKEEPER_UPGRADE_BASELINE:-${RUN_ROOT}/upgrade-baseline.json}"

if [[ -f "${PROFILE_FILE}" ]]; then
  # shellcheck disable=SC1090
  source "${PROFILE_FILE}"
else
  echo "Unknown profile: ${PROFILE_NAME} (expected innovation or production)" >&2
  exit 2
fi

: "${GATEKEEPER_LANE:=production}"
: "${GATEKEEPER_PROFILE:=gateway-production}"
: "${GATEKEEPER_GATEWAY_NAMESPACE:=mcp-gateway-system}"
: "${GATEKEEPER_GATEWAY_NAME:=mcp-gateway}"
: "${GATEKEEPER_GATEWAY_CLASS:=data-science-gateway-class}"
: "${GATEKEEPER_GATEWAY_EXTENSION_NAME:=mcp-gateway-extension}"
: "${GATEKEEPER_INTERNAL_LISTENER_NAME:=mcps}"
: "${GATEKEEPER_BACKEND_NAMESPACE:=mempalace}"
: "${GATEKEEPER_MCP_URL:=}"
: "${GATEKEEPER_MANAGE_GATEWAY_DNS:=0}"
: "${GATEKEEPER_DNS_RECORD_NAMESPACE:=openshift-ingress-operator}"
: "${GATEKEEPER_DNS_RECORD_NAME:=mcp-gateway}"
: "${GATEKEEPER_MANAGE_GATEWAY_TLS:=0}"
: "${GATEKEEPER_MANAGE_AUTHORINO_TLS_BOOTSTRAP:=1}"
: "${GATEKEEPER_GATEWAY_ROUTE_NAME:=mcp-gateway}"
: "${GATEKEEPER_GATEWAY_TLS_SECRET_NAMESPACE:=openshift-ingress}"
: "${GATEKEEPER_GATEWAY_TLS_SECRET_NAME:=apps-wildcard-tls}"
: "${GATEKEEPER_AUTH_POLICY_NAME:=mcp-auth-policy}"
: "${GATEKEEPER_INTERNAL_AUTH_POLICY_NAME:=mcps-auth-policy}"
: "${GATEKEEPER_AUTH_MODE:=tokenreview}"
: "${GATEKEEPER_ENABLE_INTERNAL_AUTHZ:=0}"
: "${GATEKEEPER_REQUIRE_INTERNAL_AUTHZ:=0}"
: "${GATEKEEPER_GATEWAY_EXPOSURE_MODE:=auto}"
: "${GATEKEEPER_EXPECTED_GATEWAY_SERVICE_TYPE:=}"
: "${GATEKEEPER_REQUIRE_INFRA_PARAMETERS_REF:=0}"
: "${GATEKEEPER_EXPECT_UNAUTHENTICATED_BACKENDS:=1}"
: "${GATEKEEPER_GATEWAY_TLS_MODE:=auto}"
: "${GATEKEEPER_PREVIEW_SOURCE:=red-hat-olm}"
: "${GATEKEEPER_PREVIEW_RELEASE_FILE:=${HERE}/releases/mcp-gateway.json}"
: "${GATEKEEPER_ADMIN_NETWORK_POLICY_NAME:=project-matrix-gatekeeper-mempalace-ingress}"
: "${GATEKEEPER_OIDC_ISSUER:=}"
: "${GATEKEEPER_OIDC_JWKS_URL:=}"
: "${GATEKEEPER_MAAS_URL:=}"
: "${GATEKEEPER_MODEL:=granite-31-8b-lab-v1}"
: "${GATEKEEPER_MCP_TOOL_NAME:=}"
: "${GATEKEEPER_MCP_TOOL_ARGUMENTS_JSON:={}}"
: "${GATEKEEPER_ROUNDTRIP:=0}"
: "${GATEKEEPER_CONFIRM_NETWORK_PROBE:=1}"
: "${GATEKEEPER_RUN_ARAMOCK_CONFORMANCE:=0}"
: "${GATEKEEPER_OPERATOR_NAMESPACES:=mcp-gateway-system,openshift-operators,redhat-ods-operator}"

load_profile_contract() {
  command -v jq >/dev/null 2>&1 || { echo "jq is required for the Gatekeeper profile catalog" >&2; exit 2; }
  [[ -f "${PROFILE_CATALOG}" ]] || { echo "Gatekeeper profile catalog is missing: ${PROFILE_CATALOG}" >&2; exit 2; }
  local profile_contract
  profile_contract="$(jq -c --arg name "${GATEKEEPER_PROFILE}" --arg lane "${GATEKEEPER_LANE}" \
    '.profiles[] | select(.name == $name and .lane == $lane)' "${PROFILE_CATALOG}")"
  if [[ -z "${profile_contract}" ]]; then
    echo "Profile ${GATEKEEPER_PROFILE} is not registered for lane ${GATEKEEPER_LANE}" >&2
    exit 2
  fi
  PROFILE_CONTRACT="${profile_contract}"
  GATEKEEPER_CATALOG_VERSION="$(jq -r '.catalogVersion' "${PROFILE_CATALOG}")"
  GATEKEEPER_SUPPORT_BOUNDARY="$(jq -r '.supportBoundary' <<<"${PROFILE_CONTRACT}")"
  GATEKEEPER_REQUIRED_CAPABILITIES="$(jq -r '.requiredCapabilityIds | join(",")' <<<"${PROFILE_CONTRACT}")"
  GATEKEEPER_OPTIONAL_CAPABILITIES="$(jq -r '.optionalCapabilityIds | join(",")' <<<"${PROFILE_CONTRACT}")"
}

load_profile_contract

support_exception_matches() {
  local version="$1" channel="$2" exception_file="${GATEKEEPER_SUPPORT_EXCEPTION_FILE:-}"
  local expires_at
  [[ -n "${exception_file}" && -f "${exception_file}" ]] || return 1
  jq -e --arg version "${version}" --arg channel "${channel}" '
    .apiVersion == "project-matrix.redhat.com/v1alpha1" and
    .kind == "GatekeeperProductionException" and
    .decision == "accept-technology-preview" and
    .component == "MCP Gateway Operator" and
    .installedVersion == $version and
    .installedChannel == $channel and
    (.approvalRef | type == "string" and length > 0) and
    (.approvedBy | type == "string" and length > 0) and
    (.scope | type == "string" and length > 0)
  ' "${exception_file}" >/dev/null 2>&1 || return 1
  expires_at="$(jq -r '.expiresAt // empty' "${exception_file}" 2>/dev/null || true)"
  [[ -n "${expires_at}" ]] || return 1
  python3 - "${expires_at}" <<'PY'
import datetime, sys
value = sys.argv[1].replace("Z", "+00:00")
try:
    expiry = datetime.datetime.fromisoformat(value)
except ValueError:
    raise SystemExit(1)
if expiry.tzinfo is None:
    raise SystemExit(1)
raise SystemExit(0 if expiry > datetime.datetime.now(datetime.timezone.utc) else 1)
PY
}

record_support_exception() {
  local exception_file="${GATEKEEPER_SUPPORT_EXCEPTION_FILE:-}" digest
  [[ -n "${exception_file}" && -f "${exception_file}" ]] || return 0
  if command -v shasum >/dev/null 2>&1; then
    digest="$(shasum -a 256 "${exception_file}" | awk '{print $1}')"
  else
    digest="$(sha256sum "${exception_file}" | awk '{print $1}')"
  fi
  log "Production support exception: ref=$(jq -r '.approvalRef' "${exception_file}" 2>/dev/null || echo unknown), approvedBy=$(jq -r '.approvedBy' "${exception_file}" 2>/dev/null || echo unknown), expiresAt=$(jq -r '.expiresAt' "${exception_file}" 2>/dev/null || echo unknown), sha256=${digest}"
}

mkdir -p "${RUN_DIR}"
REPORT="${RUN_DIR}/gatekeeper-report.md"
STATUS_FILE="${RUN_DIR}/status.env"
FAILURES=0
WARNINGS=0

timestamp() { date -u +%Y-%m-%dT%H:%M:%SZ; }
log() { printf '[%s] %s\n' "$(timestamp)" "$*" | tee -a "${REPORT}"; }
section() { printf '\n## %s\n\n' "$*" | tee -a "${REPORT}"; }
pass() { log "PASS: $*"; }
warn() { WARNINGS=$((WARNINGS + 1)); log "WARN: $*"; }
fail() { FAILURES=$((FAILURES + 1)); log "FAIL: $*"; }

redact_url() {
  # Reports may contain endpoint locations but never bearer tokens or secrets.
  printf '%s' "$1" | sed -E 's#(https?://)[^/]+#\1<configured-host>#'
}

oc_required() {
  command -v oc >/dev/null 2>&1 || { echo "oc is required" >&2; exit 2; }
  oc whoami >/dev/null 2>&1 || { echo "No active oc session; authenticate first" >&2; exit 2; }
}

json_value() {
  local expression="$1"
  python3 -c "import json,sys; x=json.load(sys.stdin); print(${expression})" 2>/dev/null || true
}

record_metadata() {
  cat >"${STATUS_FILE}" <<EOF
GATEKEEPER_RUN_ID=${RUN_ID}
GATEKEEPER_LANE=${GATEKEEPER_LANE}
GATEKEEPER_PROFILE=${GATEKEEPER_PROFILE}
GATEKEEPER_CATALOG_VERSION=${GATEKEEPER_CATALOG_VERSION}
GATEKEEPER_PHASE=$1
GATEKEEPER_FAILURES=${FAILURES}
GATEKEEPER_WARNINGS=${WARNINGS}
EOF
}

begin_report() {
  [[ -f "${REPORT}" ]] && return
  cat >"${REPORT}" <<EOF
# Project Matrix: Gatekeeper run

- Run: \`${RUN_ID}\`
- Layer: Gateway
- Code name: Gatekeeper
- Lane: \`${GATEKEEPER_LANE}\`
- Profile: \`${GATEKEEPER_PROFILE}\`
- Catalog: \`${GATEKEEPER_CATALOG_VERSION}\`
- Support boundary: ${GATEKEEPER_SUPPORT_BOUNDARY}
- Started: \`$(timestamp)\`

This report is evidence for the selected lane. It does not make a production
claim when Technology Preview, workaround, partner, community, or demo-only
dependencies are present.
EOF
  {
    printf '\n## Profile contract\n\n'
    printf -- '- Required capabilities: `%s`\n' "${GATEKEEPER_REQUIRED_CAPABILITIES}"
    printf -- '- Optional capabilities: `%s`\n' "${GATEKEEPER_OPTIONAL_CAPABILITIES:-none}"
    printf -- '- Cluster-wide mutations allowed: `%s`\n' "$(jq -r '.clusterWideMutationsAllowed' <<<"${PROFILE_CONTRACT}")"
    printf -- '- GPU provisioning allowed: `%s`\n' "$(jq -r '.gpuProvisioningAllowed' <<<"${PROFILE_CONTRACT}")"
  } >>"${REPORT}"
}

check_namespace() {
  local ns="$1"
  if oc get namespace "${ns}" >/dev/null 2>&1; then pass "namespace ${ns} exists"; else fail "namespace ${ns} is missing"; fi
}

check_crd() {
  local crd="$1"
  if oc get crd "${crd}" >/dev/null 2>&1; then pass "CRD ${crd} is installed"; else fail "CRD ${crd} is missing"; fi
}

backend_networkpolicy_is_restrictive() {
  local policy_json policy_state
  policy_json="$(oc get networkpolicy "${GATEKEEPER_BACKEND_NAMESPACE}" -n "${GATEKEEPER_BACKEND_NAMESPACE}" -o json 2>/dev/null || true)"
  policy_state="$(printf '%s' "${policy_json}" | json_value "bool(x.get('spec',{}).get('ingress')) and all(bool(rule.get('from')) for rule in x.get('spec',{}).get('ingress',[]))")"
  [[ "${policy_state}" == "True" ]]
}

admin_network_policy_is_ready() {
  local policy_json policy_state
  policy_json="$(oc get adminnetworkpolicy "${GATEKEEPER_ADMIN_NETWORK_POLICY_NAME}" -o json 2>/dev/null || true)"
  policy_state="$(printf '%s' "${policy_json}" | json_value "bool(x.get('status',{}).get('conditions')) and all(c.get('status') == 'True' for c in x.get('status',{}).get('conditions',[]))")"
  [[ "${policy_state}" == "True" ]]
}

backend_isolation_is_ready() {
  backend_networkpolicy_is_restrictive || admin_network_policy_is_ready
}

auth_policy_matches_oidc_issuer() {
  local auth_json="$1"
  [[ -n "${GATEKEEPER_OIDC_ISSUER}" ]] || return 1
  jq -e --arg issuer "${GATEKEEPER_OIDC_ISSUER}" \
    '[.. | objects | .jwt? // empty | .issuerUrl? // empty] | any(.[]; . == $issuer)' \
    <<<"${auth_json}" >/dev/null 2>&1
}

auth_policy_uses_tokenreview() {
  local auth_json="$1"
  jq -e '[.. | objects | select(has("kubernetesTokenReview"))] | length > 0' \
    <<<"${auth_json}" >/dev/null 2>&1
}

auth_policy_targets_section() {
  local auth_json="$1" section="$2"
  jq -e --arg section "${section}" \
    '.spec.targetRef.kind == "Gateway" and .spec.targetRef.name != "" and .spec.targetRef.sectionName == $section' \
    <<<"${auth_json}" >/dev/null 2>&1
}

preview_release_contract() {
  [[ "${GATEKEEPER_LANE}" == "innovation" && "${GATEKEEPER_PREVIEW_SOURCE}" == "upstream" ]] || return 0
  local release_file="${GATEKEEPER_PREVIEW_RELEASE_FILE}" expected_version expected_commit gateway_json actual_source actual_version actual_commit
  [[ -f "${release_file}" ]] || { fail "upstream preview release contract is missing: ${release_file}"; return; }
  expected_version="$(jq -r '.previewLane.version' "${release_file}")"
  expected_commit="$(jq -r '.previewLane.commit' "${release_file}")"
  gateway_json="$(oc get gateway "${GATEKEEPER_GATEWAY_NAME}" -n "${GATEKEEPER_GATEWAY_NAMESPACE}" -o json 2>/dev/null || true)"
  actual_source="$(jq -r '.metadata.labels["project-matrix.redhat.com/preview-source"] // .metadata.annotations["project-matrix.redhat.com/preview-source"] // ""' <<<"${gateway_json}" 2>/dev/null || true)"
  actual_version="$(jq -r '.metadata.labels["project-matrix.redhat.com/preview-version"] // .metadata.annotations["project-matrix.redhat.com/preview-version"] // ""' <<<"${gateway_json}" 2>/dev/null || true)"
  actual_commit="$(jq -r '.metadata.labels["project-matrix.redhat.com/preview-commit"] // .metadata.annotations["project-matrix.redhat.com/preview-commit"] // ""' <<<"${gateway_json}" 2>/dev/null || true)"
  if [[ "${actual_source}" == "upstream" && "${actual_version}" == "${expected_version}" && "${actual_commit}" == "${expected_commit}" ]]; then
    pass "preview source is pinned upstream MCP Gateway ${expected_version} (${expected_commit})"
  else
    fail "innovation lane requires upstream MCP Gateway ${expected_version} (${expected_commit}); observed ${actual_source:-unmarked} ${actual_version:-unknown} (${actual_commit:-unknown})"
  fi
  log "Preview release contract: source=upstream, version=${expected_version}, commit=${expected_commit}"
}

operator_scope_report() {
  local csv_json subscriptions matches namespace namespace_csv namespace_subscriptions
  local -a namespaces
  csv_json="$(operator_csv_inventory)"
  subscriptions='{"items":[]}'
  IFS=',' read -r -a namespaces <<<"${GATEKEEPER_OPERATOR_NAMESPACES}"
  for namespace in "${namespaces[@]}"; do
    namespace="${namespace//[[:space:]]/}"
    [[ -n "${namespace}" ]] || continue
    namespace_subscriptions="$(oc_json_or '{"items":[]}' get subscriptions -n "${namespace}")"
    subscriptions="$(printf '%s\n%s\n' "${subscriptions}" "${namespace_subscriptions}" | jq -s -c '{items: map(.items // []) | add}')"
  done
  matches="$(jq -c '[.items[]? | select((.metadata.name // "" | test("mcp-gateway"; "i")) or (.spec.displayName // "" | test("mcp gateway"; "i"))) | {namespace:.metadata.namespace,name:.metadata.name,version:.spec.version,phase:.status.phase,reason:.status.reason,operatorGroup:(.metadata.annotations["olm.operatorGroup"] // "")}]' <<<"${csv_json}" 2>/dev/null || echo '[]')"
  if [[ "$(jq 'length' <<<"${matches}")" -gt 0 ]]; then
    jq -r '.[] | "  \(.namespace)/\(.name) version=\(.version // "unknown") phase=\(.phase // "unknown") reason=\(.reason // "") operatorGroup=\(.operatorGroup // "")"' <<<"${matches}" | tee -a "${REPORT}" >/dev/null
    if jq -e 'any(.[]; .reason == "Copied")' <<<"${matches}" >/dev/null 2>&1; then
      warn "MCP Gateway CSV copies are present; the report distinguishes copied CSVs from the namespace where the controller runs"
    else
      log "MCP Gateway operator scope recorded across all namespaces"
    fi
  else
    log "No MCP Gateway CSV was found; the selected lane may be using the standalone upstream chart"
  fi
  jq -r '[.items[]? | select((.spec.name // "") == "mcp-gateway") | "  subscription=\(.metadata.namespace)/\(.metadata.name) channel=\(.spec.channel // "") approval=\(.spec.installPlanApproval // "") currentCSV=\(.status.currentCSV // "")"] | .[]' <<<"${subscriptions}" 2>/dev/null | tee -a "${REPORT}" >/dev/null || true
}

gateway_service_from_extension() {
  local extension_json private_host service_name
  extension_json="$(oc get mcpgatewayextension "${GATEKEEPER_GATEWAY_EXTENSION_NAME}" -n "${GATEKEEPER_GATEWAY_NAMESPACE}" -o json 2>/dev/null || true)"
  private_host="$(jq -r '.spec.privateHost // ""' <<<"${extension_json}" 2>/dev/null || true)"
  service_name="${private_host%%.*}"
  service_name="${service_name%%:*}"
  if [[ -z "${service_name}" ]]; then
    service_name="${GATEKEEPER_GATEWAY_NAME}-${GATEKEEPER_GATEWAY_CLASS}"
  fi
  printf '%s' "${service_name}"
}

check_gateway_exposure_contract() {
  local service_name service_json service_type route_json route_status route_target route_port gateway_json parameters_ref mode
  service_name="$(gateway_service_from_extension)"
  service_json="$(oc get svc "${service_name}" -n "${GATEKEEPER_GATEWAY_NAMESPACE}" -o json 2>/dev/null || true)"
  if [[ -z "${service_json}" ]]; then
    fail "MCP Gateway Service/${service_name} is unavailable; exposure cannot be evaluated"
    return
  fi
  service_type="$(jq -r '.spec.type // ""' <<<"${service_json}")"
  mode="${GATEKEEPER_GATEWAY_EXPOSURE_MODE}"
  [[ "${mode}" == "auto" ]] && { [[ -n "${GATEKEEPER_GATEWAY_ROUTE_NAME}" ]] && mode=openshift-route || mode=loadbalancer; }
  [[ -n "${GATEKEEPER_EXPECTED_GATEWAY_SERVICE_TYPE}" && "${service_type}" != "${GATEKEEPER_EXPECTED_GATEWAY_SERVICE_TYPE}" ]] && \
    fail "MCP Gateway Service/${service_name} type is ${service_type}; expected ${GATEKEEPER_EXPECTED_GATEWAY_SERVICE_TYPE} for ${mode}"
  if [[ "${service_type}" == "${GATEKEEPER_EXPECTED_GATEWAY_SERVICE_TYPE}" || -z "${GATEKEEPER_EXPECTED_GATEWAY_SERVICE_TYPE}" ]]; then
    pass "MCP Gateway Service/${service_name} exposure type: ${service_type} (${mode})"
  fi

  case "${mode}" in
    openshift-route)
      route_json="$(oc get route "${GATEKEEPER_GATEWAY_ROUTE_NAME}" -n "${GATEKEEPER_GATEWAY_NAMESPACE}" -o json 2>/dev/null || true)"
      route_status="$(jq -r '[.status.ingress[]?.conditions[]? | select(.type == "Admitted") | .status] | any(. == "True")' <<<"${route_json}" 2>/dev/null || echo false)"
      route_target="$(jq -r '.spec.to.name // ""' <<<"${route_json}" 2>/dev/null || true)"
      route_port="$(jq -r '.spec.port.targetPort // ""' <<<"${route_json}" 2>/dev/null || true)"
      if [[ "${route_status}" == "true" && "${route_target}" == "${service_name}" ]]; then
        pass "OpenShift Route/${GATEKEEPER_GATEWAY_ROUTE_NAME} is admitted and targets Service/${service_name}:${route_port}"
      elif [[ "${GATEKEEPER_LANE}" == "production" ]]; then
        fail "OpenShift Route/${GATEKEEPER_GATEWAY_ROUTE_NAME} is not admitted or targets the wrong Service"
      else
        warn "OpenShift Route/${GATEKEEPER_GATEWAY_ROUTE_NAME} is not admitted or targets the wrong Service"
      fi
      ;;
    loadbalancer)
      if [[ "${service_type}" == "LoadBalancer" && "$(jq '[.status.loadBalancer.ingress[]?] | length' <<<"${service_json}")" -gt 0 ]]; then
        pass "LoadBalancer Service/${service_name} has an assigned ingress address"
      else
        fail "LoadBalancer exposure selected but Service/${service_name} has no assigned ingress address"
      fi
      ;;
    clusterip)
      gateway_json="$(oc get gateway "${GATEKEEPER_GATEWAY_NAME}" -n "${GATEKEEPER_GATEWAY_NAMESPACE}" -o json 2>/dev/null || true)"
      parameters_ref="$(jq -r '.spec.infrastructure.parametersRef.name // ""' <<<"${gateway_json}" 2>/dev/null || true)"
      if [[ "${service_type}" == "ClusterIP" ]]; then
        pass "ClusterIP exposure selected for Service/${service_name}"
        if [[ -n "${parameters_ref}" ]]; then
          pass "Gateway infrastructure.parametersRef is explicit: ${parameters_ref}"
        elif [[ "${GATEKEEPER_REQUIRE_INFRA_PARAMETERS_REF:-0}" == "1" ]]; then
          fail "ClusterIP exposure requires Gateway.spec.infrastructure.parametersRef for portable infrastructure configuration"
        else
          warn "ClusterIP exposure has no Gateway.spec.infrastructure.parametersRef; portability remains advisory"
        fi
      fi
      ;;
    *)
      fail "unsupported GATEKEEPER_GATEWAY_EXPOSURE_MODE=${mode}"
      ;;
  esac
}

check_gateway_tls_contract() {
  local gateway_json https_count missing_secret listener_name secret_name secret_namespace route_termination
  gateway_json="$(oc get gateway "${GATEKEEPER_GATEWAY_NAME}" -n "${GATEKEEPER_GATEWAY_NAMESPACE}" -o json 2>/dev/null || true)"
  https_count="$(jq '[.spec.listeners[]? | select(.protocol == "HTTPS")] | length' <<<"${gateway_json}" 2>/dev/null || echo 0)"
  if [[ "${https_count}" -gt 0 ]]; then
    missing_secret=0
    while IFS=$'\t' read -r listener_name secret_name secret_namespace; do
      [[ -n "${secret_name}" ]] || continue
      secret_namespace="${secret_namespace:-${GATEKEEPER_GATEWAY_NAMESPACE}}"
      if ! oc get secret "${secret_name}" -n "${secret_namespace}" >/dev/null 2>&1; then
        fail "HTTPS listener ${listener_name} references missing TLS Secret ${secret_namespace}/${secret_name}"
        missing_secret=1
      fi
    done < <(jq -r '.spec.listeners[]? | select(.protocol == "HTTPS") | . as $listener | (.tls.certificateRefs[]? // {}) | [$listener.name, .name, (.namespace // "")] | @tsv' <<<"${gateway_json}" 2>/dev/null || true)
    [[ "${missing_secret}" == "0" ]] && pass "all HTTPS Gateway listener certificate references resolve to Secrets"
  elif [[ "${GATEKEEPER_GATEWAY_TLS_MODE}" == "gateway-https" ]]; then
    fail "Gateway HTTPS TLS mode selected but no HTTPS listener exists"
  else
    route_termination="$(oc get route "${GATEKEEPER_GATEWAY_ROUTE_NAME}" -n "${GATEKEEPER_GATEWAY_NAMESPACE}" -o jsonpath='{.spec.tls.termination}' 2>/dev/null || true)"
    if [[ "${route_termination}" == "edge" || "${route_termination}" == "reencrypt" || "${route_termination}" == "passthrough" ]]; then
      pass "TLS is terminated through the OpenShift Route (${route_termination}); Gateway certificate discovery is not required"
    else
      warn "no HTTPS Gateway listener or admitted OpenShift TLS Route was detected"
    fi
  fi
}

check_backend_credential_contract() {
  local registrations credentialed
  registrations="$(oc get mcpserverregistration -A -o json 2>/dev/null || echo '{"items":[]}')"
  credentialed="$(jq '[.items[]? | select(.spec.credentialRef != null)] | length' <<<"${registrations}" 2>/dev/null || echo 0)"
  if [[ "${GATEKEEPER_EXPECT_UNAUTHENTICATED_BACKENDS:-1}" == "1" && "${credentialed}" != "0" ]]; then
    fail "${credentialed} MCPServerRegistration resource(s) declare credentialRef although the selected backend contract is unauthenticated"
  else
    pass "backend credential contract is explicit; unauthenticated registrations omit credentialRef"
  fi
}

check_internal_auth_policy_contract() {
  [[ "${GATEKEEPER_REQUIRE_INTERNAL_AUTHZ}" == "1" ]] || return 0
  local auth_json auth_conditions
  auth_json="$(oc get authpolicy "${GATEKEEPER_INTERNAL_AUTH_POLICY_NAME}" -n "${GATEKEEPER_GATEWAY_NAMESPACE}" -o json 2>/dev/null || true)"
  auth_conditions="$(printf '%s' "${auth_json}" | json_value "[(c.get('type'),c.get('status')) for c in x.get('status',{}).get('conditions',[])]")"
  if [[ -n "${auth_json}" && "${auth_conditions}" == *"('Accepted', 'True')"* && "${auth_conditions}" == *"('Enforced', 'True')"* ]] && auth_policy_targets_section "${auth_json}" "${GATEKEEPER_INTERNAL_LISTENER_NAME}"; then
    if [[ "${GATEKEEPER_AUTH_MODE}" == "tokenreview" ]] && auth_policy_uses_tokenreview "${auth_json}"; then
      pass "internal AuthPolicy/${GATEKEEPER_INTERNAL_AUTH_POLICY_NAME} targets ${GATEKEEPER_INTERNAL_LISTENER_NAME} with TokenReview"
    elif [[ "${GATEKEEPER_AUTH_MODE}" == "oidc" ]] && auth_policy_matches_oidc_issuer "${auth_json}"; then
      pass "internal AuthPolicy/${GATEKEEPER_INTERNAL_AUTH_POLICY_NAME} targets ${GATEKEEPER_INTERNAL_LISTENER_NAME} with the configured OIDC issuer"
    else
      fail "internal AuthPolicy/${GATEKEEPER_INTERNAL_AUTH_POLICY_NAME} is enforced but does not match GATEKEEPER_AUTH_MODE=${GATEKEEPER_AUTH_MODE}"
    fi
  elif [[ "${GATEKEEPER_LANE}" == "production" ]]; then
    fail "internal AuthPolicy/${GATEKEEPER_INTERNAL_AUTH_POLICY_NAME} must be Accepted, Enforced, and target listener ${GATEKEEPER_INTERNAL_LISTENER_NAME}"
  else
    warn "internal AuthPolicy/${GATEKEEPER_INTERNAL_AUTH_POLICY_NAME} is not yet Accepted/Enforced on listener ${GATEKEEPER_INTERNAL_LISTENER_NAME}"
  fi
}

mcp_normalize_response() {
  local response_file="$1" normalized
  jq -e . "${response_file}" >/dev/null 2>&1 && return 0
  normalized="$(mktemp "${RUN_DIR}/mcp-json.XXXXXX")"
  sed -n 's/^data:[[:space:]]*//p' "${response_file}" | head -n 1 >"${normalized}"
  mv "${normalized}" "${response_file}"
}

check_component_status() {
  local kind="$1" name="$2" ns="$3" label="$4"
  local phase
  phase="$(oc get "${kind}" "${name}" -n "${ns}" -o json 2>/dev/null | json_value "x.get('status',{}).get('phase','')")"
  if [[ -n "${phase}" ]]; then pass "${label}: ${phase}"; else fail "${label} is unavailable"; fi
}

check_gateway_status() {
  local conditions programmed accepted
  conditions="$(oc get gateway "${GATEKEEPER_GATEWAY_NAME}" -n "${GATEKEEPER_GATEWAY_NAMESPACE}" -o json 2>/dev/null | json_value "[(c.get('type'),c.get('status'),c.get('message','')) for c in x.get('status',{}).get('conditions',[])]")"
  programmed="$(printf '%s' "${conditions}" | grep -o "('Programmed', 'True'" || true)"
  accepted="$(printf '%s' "${conditions}" | grep -o "('Accepted', 'True'" || true)"
  if [[ -n "${programmed}" && -n "${accepted}" ]]; then
    pass "Gateway/${GATEKEEPER_GATEWAY_NAME}: Accepted=True, Programmed=True"
  else
    fail "Gateway/${GATEKEEPER_GATEWAY_NAME} is not fully programmed: ${conditions:-no conditions}"
  fi
}

gateway_api_compatibility_ready() {
  local mesh_ready gatewayclass_accepted gateway_accepted gateway_programmed
  mesh_ready="$(oc get istio.sailoperator.io openshift-gateway -n openshift-ingress \
    -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || true)"
  gatewayclass_accepted="$(oc get gatewayclass "${GATEKEEPER_GATEWAY_CLASS}" \
    -o jsonpath='{.status.conditions[?(@.type=="Accepted")].status}' 2>/dev/null || true)"
  gateway_accepted="$(oc get gateway "${GATEKEEPER_GATEWAY_NAME}" -n "${GATEKEEPER_GATEWAY_NAMESPACE}" \
    -o jsonpath='{.status.conditions[?(@.type=="Accepted")].status}' 2>/dev/null || true)"
  gateway_programmed="$(oc get gateway "${GATEKEEPER_GATEWAY_NAME}" -n "${GATEKEEPER_GATEWAY_NAMESPACE}" \
    -o jsonpath='{.status.conditions[?(@.type=="Programmed")].status}' 2>/dev/null || true)"
  [[ "${mesh_ready}" == "True" &&
     "${gatewayclass_accepted}" == "True" &&
     "${gateway_accepted}" == "True" &&
     "${gateway_programmed}" == "True" ]]
}

gateway_public_dns_values() {
  local hostname target gateway_json
  hostname="$(oc get gateway "${GATEKEEPER_GATEWAY_NAME}" -n "${GATEKEEPER_GATEWAY_NAMESPACE}" \
    -o jsonpath='{.spec.listeners[0].hostname}' 2>/dev/null || true)"
  if [[ -z "${hostname}" ]]; then
    # MCP Gateway v0.7 stores the public hostname on its owned HTTPRoute while
    # the Gateway listener remains an unnamed port listener.
    hostname="$(oc get httproute mcp-gateway-route -n "${GATEKEEPER_GATEWAY_NAMESPACE}" \
      -o jsonpath='{.spec.hostnames[0]}' 2>/dev/null || true)"
  fi
  target="$(oc get gateway "${GATEKEEPER_GATEWAY_NAME}" -n "${GATEKEEPER_GATEWAY_NAMESPACE}" \
    -o jsonpath='{.status.addresses[0].value}' 2>/dev/null || true)"
  gateway_json="$(oc get gateway "${GATEKEEPER_GATEWAY_NAME}" -n "${GATEKEEPER_GATEWAY_NAMESPACE}" -o json 2>/dev/null || true)"
  # MCP Gateway's documented same-port HTTP/HTTP topology is exposed through
  # an OpenShift edge Route. Its public DNS must therefore target the router
  # wildcard, not the raw Gateway LoadBalancer address.
  if jq -e --arg internal "${GATEKEEPER_INTERNAL_LISTENER_NAME}" \
    '([.spec.listeners[]? | select(.name == "mcp" and .protocol == "HTTP")] | length) == 1 and
     ([.spec.listeners[]? | select(.name == $internal and .protocol == "HTTP")] | length) == 1' \
    <<<"${gateway_json}" >/dev/null 2>&1; then
    target="$(oc get dnsrecord default-wildcard -n "${GATEKEEPER_DNS_RECORD_NAMESPACE}" \
      -o jsonpath='{.spec.targets[0]}' 2>/dev/null || true)"
  fi
  [[ -n "${hostname}" && -n "${target}" ]] || return 1
  printf '%s\n%s\n' "${hostname}" "${target}"
}

ensure_gateway_dns() {
  [[ "${GATEKEEPER_MANAGE_GATEWAY_DNS}" == "1" ]] || {
    log "Gateway DNS reconciliation disabled by profile"
    return 0
  }

  local dns_values dns_name dns_target
  dns_values="$(gateway_public_dns_values || true)"
  dns_name="$(sed -n '1p' <<<"${dns_values}")"
  dns_target="$(sed -n '2p' <<<"${dns_values}")"
  if [[ -z "${dns_name}" || -z "${dns_target}" ]]; then
    fail "Gateway DNS reconciliation requires a listener hostname and programmed Gateway address"
    return 1
  fi

  cat <<YAML | oc apply -f - | tee -a "${REPORT}"
apiVersion: ingress.operator.openshift.io/v1
kind: DNSRecord
metadata:
  name: ${GATEKEEPER_DNS_RECORD_NAME}
  namespace: ${GATEKEEPER_DNS_RECORD_NAMESPACE}
  labels:
    project-matrix.redhat.com/component: gatekeeper
    project-matrix.redhat.com/managed: "true"
spec:
  dnsManagementPolicy: Managed
  dnsName: ${dns_name}.
  recordTTL: 120
  recordType: CNAME
  targets:
  - ${dns_target}
YAML

  if oc wait --for='jsonpath={.status.zones[0].conditions[0].status}=True' \
    "dnsrecord/${GATEKEEPER_DNS_RECORD_NAME}" -n "${GATEKEEPER_DNS_RECORD_NAMESPACE}" --timeout=90s >/dev/null 2>&1; then
    pass "Gateway DNS record published: ${dns_name} -> ${dns_target}"
  else
    fail "Gateway DNS record was not confirmed Published: ${dns_name} -> ${dns_target}"
    return 1
  fi
}

ensure_authorino_tls_bootstrap() {
  [[ "${GATEKEEPER_MANAGE_AUTHORINO_TLS_BOOTSTRAP}" == "1" ]] || {
    log "OpenShift AI Authorino TLS bootstrap disabled by profile"
    return 0
  }

  # This is the Red Hat OpenShift AI integration point. It asks the ODH model
  # controller to create the operator-owned EnvoyFilter that trusts the
  # OpenShift service CA when the Gateway calls Authorino over gRPC/TLS. Keep
  # custom Gateway/AuthPolicy ownership explicit so the controller does not
  # add MaaS authorization rules to a non-MaaS Gateway.
  oc annotate gateway "${GATEKEEPER_GATEWAY_NAME}" \
    -n "${GATEKEEPER_GATEWAY_NAMESPACE}" \
    security.opendatahub.io/authorino-tls-bootstrap=true \
    opendatahub.io/managed=false --overwrite | tee -a "${REPORT}"

  local bootstrap_count=0 attempt
  for attempt in {1..30}; do
    bootstrap_count="$(oc get envoyfilter -n "${GATEKEEPER_GATEWAY_NAMESPACE}" -o json 2>/dev/null | \
      jq --arg gateway "${GATEKEEPER_GATEWAY_NAME}" '[.items[]? |
        select((.spec.targetRefs // []) | any(.name == $gateway)) |
        .spec.configPatches[]? |
        select(.applyTo == "CLUSTER" and
          (.patch.value.transport_socket.name // "") == "envoy.transport_sockets.tls")] | length' 2>/dev/null || echo 0)"
    if [[ "${bootstrap_count}" -gt 0 ]]; then
      pass "OpenShift AI Authorino TLS bootstrap is operator-owned for Gateway/${GATEKEEPER_GATEWAY_NAME}"
      return 0
    fi
    sleep 2
  done

  if [[ "${GATEKEEPER_LANE}" == "production" ]]; then
    fail "OpenShift AI did not create an Authorino TLS EnvoyFilter for Gateway/${GATEKEEPER_GATEWAY_NAME}"
    return 1
  fi
  warn "OpenShift AI Authorino TLS EnvoyFilter is not present yet; innovation evidence records the missing bootstrap"
}

ensure_mcp_gateway_edge_route() {
  local gateway_json dns_values hostname private_host service_name listener_ports
  gateway_json="$(oc get gateway "${GATEKEEPER_GATEWAY_NAME}" -n "${GATEKEEPER_GATEWAY_NAMESPACE}" -o json 2>/dev/null || true)"
  dns_values="$(gateway_public_dns_values || true)"
  hostname="$(sed -n '1p' <<<"${dns_values}")"
  private_host="$(oc get mcpgatewayextension "${GATEKEEPER_GATEWAY_EXTENSION_NAME}" \
    -n "${GATEKEEPER_GATEWAY_NAMESPACE}" -o jsonpath='{.spec.privateHost}' 2>/dev/null || true)"
  service_name="${private_host%%.*}"
  service_name="${service_name%%:*}"
  listener_ports="$(jq -c '[.spec.listeners[]? | {name,port,protocol}]' <<<"${gateway_json}" 2>/dev/null || echo '[]')"

  [[ -n "${hostname}" && -n "${service_name}" ]] || {
    fail "MCP Gateway edge Route requires a public hostname and MCP Gateway Service"
    return 1
  }
  jq -e --arg internal "${GATEKEEPER_INTERNAL_LISTENER_NAME}" \
    '([.[] | select(.name == "mcp" and .protocol == "HTTP")] | length) == 1 and
     ([.[] | select(.name == $internal and .protocol == "HTTP")] | length) == 1 and
     ([.[] | select(.name == "mcp")][0].port) == ([.[] | select(.name == $internal)][0].port)' \
    <<<"${listener_ports}" >/dev/null || {
    fail "MCP Gateway must retain HTTP/HTTP same-port listeners for public routing and internal tool-call rerouting"
    return 1
  }

  cat <<YAML | oc apply -f - | tee -a "${REPORT}"
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: ${GATEKEEPER_GATEWAY_ROUTE_NAME}
  namespace: ${GATEKEEPER_GATEWAY_NAMESPACE}
  labels:
    project-matrix.redhat.com/component: gatekeeper
    project-matrix.redhat.com/managed: "true"
spec:
  host: ${hostname}
  to:
    kind: Service
    name: ${service_name}
    weight: 100
  port:
    targetPort: mcp
  tls:
    termination: edge
    insecureEdgeTerminationPolicy: Redirect
  wildcardPolicy: None
YAML

  if oc wait --for='jsonpath={.status.ingress[0].conditions[?(@.type=="Admitted")].status}=True' \
    "route/${GATEKEEPER_GATEWAY_ROUTE_NAME}" -n "${GATEKEEPER_GATEWAY_NAMESPACE}" --timeout=90s >/dev/null 2>&1; then
    pass "MCP Gateway public HTTPS edge Route is admitted: ${hostname}"
  else
    fail "MCP Gateway public HTTPS edge Route was not admitted: ${hostname}"
    return 1
  fi
}

ensure_gateway_tls() {
  [[ "${GATEKEEPER_MANAGE_GATEWAY_TLS}" == "1" ]] || {
    log "Gateway TLS reconciliation disabled by profile"
    return 0
  }

  local gateway_json
  gateway_json="$(oc get gateway "${GATEKEEPER_GATEWAY_NAME}" -n "${GATEKEEPER_GATEWAY_NAMESPACE}" -o json 2>/dev/null || true)"
  if jq -e --arg internal "${GATEKEEPER_INTERNAL_LISTENER_NAME}" \
    '([.spec.listeners[]? | select(.name == "mcp")] | length) == 1 and
     ([.spec.listeners[]? | select(.name == $internal)] | length) == 1' \
    <<<"${gateway_json}" >/dev/null 2>&1; then
    ensure_mcp_gateway_edge_route
    ensure_authorino_tls_bootstrap
    return
  fi

  oc get secret "${GATEKEEPER_GATEWAY_TLS_SECRET_NAME}" -n "${GATEKEEPER_GATEWAY_TLS_SECRET_NAMESPACE}" >/dev/null 2>&1 || {
    fail "Gateway TLS secret ${GATEKEEPER_GATEWAY_TLS_SECRET_NAMESPACE}/${GATEKEEPER_GATEWAY_TLS_SECRET_NAME} is missing"
    return 1
  }

  cat <<YAML | oc apply -f - | tee -a "${REPORT}"
apiVersion: gateway.networking.k8s.io/v1beta1
kind: ReferenceGrant
metadata:
  name: project-matrix-mcp-gateway-tls
  namespace: ${GATEKEEPER_GATEWAY_TLS_SECRET_NAMESPACE}
  labels:
    project-matrix.redhat.com/component: gatekeeper
    project-matrix.redhat.com/managed: "true"
spec:
  from:
  - group: gateway.networking.k8s.io
    kind: Gateway
    namespace: ${GATEKEEPER_GATEWAY_NAMESPACE}
  to:
  - group: ""
    kind: Secret
    name: ${GATEKEEPER_GATEWAY_TLS_SECRET_NAME}
YAML

  local gateway_json dns_values dns_name
  gateway_json="$(oc get gateway "${GATEKEEPER_GATEWAY_NAME}" -n "${GATEKEEPER_GATEWAY_NAMESPACE}" -o json 2>/dev/null || true)"
  dns_values="$(gateway_public_dns_values || true)"
  dns_name="$(sed -n '1p' <<<"${dns_values}")"
  [[ -n "${gateway_json}" && -n "${dns_name}" ]] || {
    fail "Gateway TLS reconciliation requires a discoverable Gateway hostname"
    return 1
  }
  python3 - "${gateway_json}" "${dns_name}" "${GATEKEEPER_GATEWAY_TLS_SECRET_NAMESPACE}" "${GATEKEEPER_GATEWAY_TLS_SECRET_NAME}" <<'PY' | oc apply -f - | tee -a "${REPORT}"
import json, sys
gateway, hostname, secret_namespace, secret_name = sys.argv[1:]
obj = json.loads(gateway)
listener = obj["spec"]["listeners"][0]
# Keep the listener hostname-less. MCP backend HTTPRoutes intentionally use
# internal hostnames (for example mempalace-backend) while the public route uses
# the apps hostname; a hostname constraint would make those registrations
# NotReady. The wildcard certificate still covers the public SNI.
listener.pop("hostname", None)
listener["protocol"] = "HTTPS"
listener["tls"] = {
    "mode": "Terminate",
    "certificateRefs": [{"group": "", "kind": "Secret", "name": secret_name, "namespace": secret_namespace}],
}

print(json.dumps({"apiVersion": obj["apiVersion"], "kind": obj["kind"], "metadata": {"name": obj["metadata"]["name"], "namespace": obj["metadata"]["namespace"]}, "spec": obj["spec"]}))
PY

  if oc wait --for='jsonpath={.status.listeners[0].conditions[?(@.type=="Programmed")].status}=True' \
    "gateway/${GATEKEEPER_GATEWAY_NAME}" -n "${GATEKEEPER_GATEWAY_NAMESPACE}" --timeout=120s >/dev/null 2>&1; then
    pass "Gateway/${GATEKEEPER_GATEWAY_NAME} is programmed with HTTPS"
  else
    fail "Gateway/${GATEKEEPER_GATEWAY_NAME} was not confirmed programmed with HTTPS"
    return 1
  fi
  ensure_authorino_tls_bootstrap
}

check_gateway_extension_contract() {
  local extension_json gateway_json section private_host public_host
  local private_host_name private_host_port listener_port internal_listener_port service_type route_rule_names
  extension_json="$(oc get mcpgatewayextension "${GATEKEEPER_GATEWAY_EXTENSION_NAME}" -n "${GATEKEEPER_GATEWAY_NAMESPACE}" -o json 2>/dev/null || true)"
  if [[ -z "${extension_json}" ]]; then
    if [[ "${GATEKEEPER_LANE}" == "production" ]]; then
      fail "MCPGatewayExtension/${GATEKEEPER_GATEWAY_EXTENSION_NAME} is unavailable"
    else
      warn "MCPGatewayExtension/${GATEKEEPER_GATEWAY_EXTENSION_NAME} is unavailable"
    fi
    return
  fi

  section="$(jq -r '.spec.targetRef.sectionName // ""' <<<"${extension_json}")"
  private_host="$(jq -r '.spec.privateHost // ""' <<<"${extension_json}")"
  public_host="$(jq -r '.spec.publicHost // ""' <<<"${extension_json}")"
  if [[ "$(jq -r '[.status.conditions[]? | select(.type == "Ready" and .status == "True")] | length' <<<"${extension_json}")" == "1" ]]; then
    pass "MCPGatewayExtension/${GATEKEEPER_GATEWAY_EXTENSION_NAME}: Ready"
  else
    fail "MCPGatewayExtension/${GATEKEEPER_GATEWAY_EXTENSION_NAME} is not Ready"
  fi

  gateway_json="$(oc get gateway "${GATEKEEPER_GATEWAY_NAME}" -n "${GATEKEEPER_GATEWAY_NAMESPACE}" -o json 2>/dev/null || true)"
  listener_port="$(jq -r --arg section "${section}" '.spec.listeners[]? | select(.name == $section) | .port' <<<"${gateway_json}" | head -1)"
  if [[ -z "${section}" || -z "${listener_port}" ]]; then
    fail "MCPGatewayExtension target sectionName ${section:-<empty>} does not resolve to a Gateway listener"
  else
    pass "MCPGatewayExtension sectionName ${section} resolves to Gateway listener port ${listener_port}"
  fi

  internal_listener_port="$(jq -r --arg section "${GATEKEEPER_INTERNAL_LISTENER_NAME}" '.spec.listeners[]? | select(.name == $section) | .port' <<<"${gateway_json}" | head -1)"
  if [[ -z "${internal_listener_port}" ]]; then
    if [[ "${GATEKEEPER_LANE}" == "production" ]]; then
      fail "Gateway/${GATEKEEPER_GATEWAY_NAME} is missing required internal listener ${GATEKEEPER_INTERNAL_LISTENER_NAME} for authenticated tools/call authorization"
    else
      warn "Gateway/${GATEKEEPER_GATEWAY_NAME} is missing internal listener ${GATEKEEPER_INTERNAL_LISTENER_NAME}; tools/call authorization remains advisory"
    fi
  elif [[ -n "${listener_port}" && "${internal_listener_port}" != "${listener_port}" ]]; then
    fail "public listener port ${listener_port} and internal ${GATEKEEPER_INTERNAL_LISTENER_NAME} listener port ${internal_listener_port} differ"
  else
    pass "internal ${GATEKEEPER_INTERNAL_LISTENER_NAME} listener shares port ${internal_listener_port}"
  fi

  private_host_name="$(python3 -c 'import sys; from urllib.parse import urlsplit; value=sys.argv[1]; parsed=urlsplit(value if "://" in value else "tcp://" + value); print(parsed.hostname or "")' "${private_host}")"
  private_host_port="$(python3 -c 'import sys; from urllib.parse import urlsplit; value=sys.argv[1]; parsed=urlsplit(value if "://" in value else "tcp://" + value); print(parsed.port or "")' "${private_host}")"
  # privateHost is normally a Kubernetes service FQDN; the Service API lookup
  # uses the first DNS label while the port comparison retains the full value.
  private_host_name="${private_host_name%%.*}"
  if [[ -z "${private_host_name}" || -z "${private_host_port}" ]]; then
    fail "MCPGatewayExtension privateHost is not a parseable host:port value"
  elif ! oc get svc "${private_host_name}" -n "${GATEKEEPER_GATEWAY_NAMESPACE}" >/dev/null 2>&1; then
    fail "MCPGatewayExtension privateHost ${private_host_name} does not resolve to a Service in ${GATEKEEPER_GATEWAY_NAMESPACE}"
  else
    service_type="$(oc get svc "${private_host_name}" -n "${GATEKEEPER_GATEWAY_NAMESPACE}" -o jsonpath='{.spec.type}' 2>/dev/null || true)"
    if [[ "$(oc get svc "${private_host_name}" -n "${GATEKEEPER_GATEWAY_NAMESPACE}" -o json | jq --argjson port "${private_host_port}" '[.spec.ports[]? | select(.port == $port or (.targetPort | tostring) == ($port | tostring))] | length')" -gt 0 ]]; then
      pass "MCPGatewayExtension privateHost resolves to Service/${private_host_name}:${private_host_port} (${service_type})"
    else
      fail "MCPGatewayExtension privateHost port ${private_host_port} is not served by Service/${private_host_name}"
    fi
  fi

  if [[ -n "${listener_port}" && -n "${private_host_port}" && "${listener_port}" == "${private_host_port}" ]]; then
    pass "public and private MCP paths share listener port ${listener_port}"
  elif [[ -n "${listener_port}" && -n "${private_host_port}" ]]; then
    fail "public listener port ${listener_port} and privateHost port ${private_host_port} differ"
  fi

  route_rule_names="$(oc get httproute -n "${GATEKEEPER_GATEWAY_NAMESPACE}" -o json 2>/dev/null | jq '[.items[]? | .spec.rules[]? | select(has("name"))] | length' 2>/dev/null || echo 0)"
  if [[ "${route_rule_names}" == "0" ]]; then
    pass "HTTPRoute rules use fields served by the installed CRD schema"
  else
    fail "${route_rule_names} HTTPRoute rule(s) contain unsupported spec.rules[].name fields"
  fi

  [[ -n "${public_host}" ]] && log "MCPGatewayExtension publicHost: $(redact_url "https://${public_host}")"
}

preflight() {
  oc_required
  begin_report
  section "Preflight"
  log "Profile contract: ${GATEKEEPER_PROFILE} (${GATEKEEPER_CATALOG_VERSION})"
  log "Required capabilities: ${GATEKEEPER_REQUIRED_CAPABILITIES}"
  log "OpenShift identity: $(oc whoami)"
  log "OpenShift server: $(oc whoami --show-server 2>/dev/null || echo unavailable)"
  oc version 2>&1 | sed -n '1,5p' | tee -a "${REPORT}" >/dev/null || true

  check_namespace "${GATEKEEPER_GATEWAY_NAMESPACE}"
  check_namespace "${GATEKEEPER_BACKEND_NAMESPACE}"
  check_crd "gateways.gateway.networking.k8s.io"
  check_crd "httproutes.gateway.networking.k8s.io"
  check_crd "mcpserverregistrations.mcp.kuadrant.io"

  if oc get datasciencecluster default-dsc >/dev/null 2>&1; then
    local dsc_phase
    dsc_phase="$(oc get datasciencecluster default-dsc -o json 2>/dev/null | json_value "x.get('status',{}).get('phase','')")"
    [[ "${dsc_phase}" == "Ready" ]] && pass "OpenShift AI DataScienceCluster/default-dsc: Ready" || fail "OpenShift AI DataScienceCluster/default-dsc: ${dsc_phase:-unknown}"
  else
    fail "OpenShift AI DataScienceCluster/default-dsc is unavailable"
  fi

  local gateway_status
  gateway_status="$(oc get gateway "${GATEKEEPER_GATEWAY_NAME}" -n "${GATEKEEPER_GATEWAY_NAMESPACE}" -o json 2>/dev/null | json_value "[(c.get('type'),c.get('status'),c.get('message','')) for c in x.get('status',{}).get('conditions',[])]")"
  if [[ -n "${gateway_status}" ]]; then pass "Gateway/${GATEKEEPER_GATEWAY_NAME} exists"; else fail "Gateway/${GATEKEEPER_GATEWAY_NAME} is unavailable"; fi
  check_gateway_extension_contract
  preview_release_contract
  operator_scope_report
  check_gateway_exposure_contract
  check_gateway_tls_contract
  check_backend_credential_contract
  check_internal_auth_policy_contract

  local ingress_json ingress_degraded ingress_reason ingress_message
  ingress_json="$(oc get co ingress -o json 2>/dev/null || true)"
  ingress_degraded="$(printf '%s' "${ingress_json}" | json_value "next((c.get('status') for c in x.get('status',{}).get('conditions',[]) if c.get('type')=='Degraded'),'')")"
  ingress_reason="$(printf '%s' "${ingress_json}" | json_value "next((c.get('reason','') for c in x.get('status',{}).get('conditions',[]) if c.get('type')=='Degraded'),'')")"
  ingress_message="$(printf '%s' "${ingress_json}" | json_value "next((c.get('message','') for c in x.get('status',{}).get('conditions',[]) if c.get('type')=='Degraded'),'')")"
  if [[ "${ingress_degraded}" == "True" ]]; then
    if [[ "${ingress_reason}" == "GatewayAPIInstallConflict" ]] && gateway_api_compatibility_ready; then
      warn "ingress ClusterOperator reports GatewayAPIInstallConflict, but the Mesh 3 control plane, GatewayClass/${GATEKEEPER_GATEWAY_CLASS}, and Gateway/${GATEKEEPER_GATEWAY_NAME} are operational; treating this known ownership condition as non-blocking for Gatekeeper"
    elif [[ "${GATEKEEPER_LANE}" == "production" ]]; then
      fail "ingress ClusterOperator is Degraded: ${ingress_message}"
    else
      warn "ingress ClusterOperator is Degraded: ${ingress_message}"
    fi
  else
    pass "ingress ClusterOperator is not degraded"
  fi

  if backend_isolation_is_ready; then
    pass "effective backend isolation is enforced for the Gateway backend"
  elif [[ "${GATEKEEPER_LANE}" == "production" ]]; then
    fail "backend NetworkPolicy remains permissive; direct Gateway bypass is not blocked"
  else
    warn "backend NetworkPolicy remains permissive; direct Gateway bypass must be resolved before production promotion"
  fi

  local gateway_csv mesh_csv gateway_csv_name gateway_version gateway_channel
  gateway_csv="$(oc get csv -n "${GATEKEEPER_GATEWAY_NAMESPACE}" --no-headers 2>/dev/null | grep -Ei 'mcp-gateway' || true)"
  mesh_csv="$(oc get csv -n openshift-operators --no-headers 2>/dev/null | grep -Ei 'servicemeshoperator' || true)"
  if [[ -n "${gateway_csv}" ]]; then
    printf '%s\n' "${gateway_csv}" | sed 's/^/  /' | tee -a "${REPORT}" >/dev/null
    gateway_csv_name="$(awk 'NR == 1 {print $1}' <<<"${gateway_csv}")"
    gateway_version="$(oc get csv "${gateway_csv_name}" -n "${GATEKEEPER_GATEWAY_NAMESPACE}" -o jsonpath='{.spec.version}' 2>/dev/null || true)"
    gateway_channel="$(oc get subscription mcp-gateway -n "${GATEKEEPER_GATEWAY_NAMESPACE}" -o jsonpath='{.spec.channel}' 2>/dev/null || true)"
    if [[ "${GATEKEEPER_ALLOW_TECH_PREVIEW}" == "1" ]]; then
      warn "MCP Gateway dependency is on a Technology Preview channel (${gateway_version:-unknown}/${gateway_channel:-unknown})"
    elif support_exception_matches "${gateway_version}" "${gateway_channel}"; then
      warn "MCP Gateway Technology Preview accepted under explicit Production exception (${gateway_version}/${gateway_channel})"
      record_support_exception
    else
      fail "MCP Gateway Technology Preview dependency blocks the Production lane (${gateway_version:-unknown}/${gateway_channel:-unknown}); provide a supported channel or a valid GATEKEEPER_SUPPORT_EXCEPTION_FILE"
    fi
  else
    pass "no MCP Gateway Technology Preview dependency was detected"
  fi
  if [[ -n "${mesh_csv}" ]]; then
    printf '%s\n' "${mesh_csv}" | sed 's/^/  /' | tee -a "${REPORT}" >/dev/null
    log "Service Mesh prerequisite detected; it is evaluated separately from the MCP Gateway support gate"
  fi

  case "${GATEKEEPER_AUTH_MODE}" in
    tokenreview)
      log "OpenShift-native Kubernetes TokenReview authentication selected"
      ;;
    oidc)
      if [[ "${GATEKEEPER_LANE}" == "production" && -z "${GATEKEEPER_OIDC_ISSUER}" ]]; then
        fail "production lane with GATEKEEPER_AUTH_MODE=oidc requires GATEKEEPER_OIDC_ISSUER"
      elif [[ -n "${GATEKEEPER_OIDC_ISSUER}" ]]; then
        log "OIDC issuer configured: $(redact_url "${GATEKEEPER_OIDC_ISSUER}")"
      else
        warn "OIDC issuer is not configured; native OIDC remains unselected"
      fi
      ;;
    *)
      fail "unsupported GATEKEEPER_AUTH_MODE=${GATEKEEPER_AUTH_MODE}; expected tokenreview or oidc"
      ;;
  esac

  if [[ "${GATEKEEPER_LANE}" == "production" && -z "${GATEKEEPER_MCP_URL}" ]]; then
    fail "production lane requires GATEKEEPER_MCP_URL for edge validation"
  elif [[ "${GATEKEEPER_LANE}" == "production" && "${GATEKEEPER_MCP_URL}" != https://* ]]; then
    fail "production lane requires an HTTPS MCP endpoint; the configured Gateway edge is not encrypted"
  fi

  if [[ "${GATEKEEPER_MANAGE_GATEWAY_DNS}" == "1" ]]; then
    local dns_values dns_name dns_target dns_status
    dns_values="$(gateway_public_dns_values || true)"
    dns_name="$(sed -n '1p' <<<"${dns_values}")"
    dns_target="$(sed -n '2p' <<<"${dns_values}")"
    dns_status="$(oc get dnsrecord "${GATEKEEPER_DNS_RECORD_NAME}" -n "${GATEKEEPER_DNS_RECORD_NAMESPACE}" -o jsonpath='{.status.zones[0].conditions[0].status}' 2>/dev/null || true)"
    if [[ -n "${dns_name}" && -n "${dns_target}" && "${dns_status}" == "True" ]]; then
      pass "Gateway DNS record is Published: ${dns_name} -> ${dns_target}"
    else
      fail "Gateway DNS record is not Published for the programmed Gateway address"
    fi
  fi

  if [[ "${GATEKEEPER_MANAGE_GATEWAY_TLS}" == "1" ]]; then
    local listener_protocol auth_conditions gateway_json route_admitted route_termination
    gateway_json="$(oc get gateway "${GATEKEEPER_GATEWAY_NAME}" -n "${GATEKEEPER_GATEWAY_NAMESPACE}" -o json 2>/dev/null || true)"
    listener_protocol="$(jq -r '.spec.listeners[0].protocol // ""' <<<"${gateway_json}" 2>/dev/null || true)"
    if jq -e --arg internal "${GATEKEEPER_INTERNAL_LISTENER_NAME}" \
      '([.spec.listeners[]? | select(.name == "mcp" and .protocol == "HTTP")] | length) == 1 and
       ([.spec.listeners[]? | select(.name == $internal and .protocol == "HTTP")] | length) == 1' \
      <<<"${gateway_json}" >/dev/null 2>&1; then
      route_admitted="$(oc get route "${GATEKEEPER_GATEWAY_ROUTE_NAME}" -n "${GATEKEEPER_GATEWAY_NAMESPACE}" -o jsonpath='{.status.ingress[0].conditions[?(@.type=="Admitted")].status}' 2>/dev/null || true)"
      route_termination="$(oc get route "${GATEKEEPER_GATEWAY_ROUTE_NAME}" -n "${GATEKEEPER_GATEWAY_NAMESPACE}" -o jsonpath='{.spec.tls.termination}' 2>/dev/null || true)"
      if [[ "${route_admitted}" == "True" && "${route_termination}" == "edge" ]]; then
        pass "MCP Gateway uses an admitted OpenShift edge TLS Route with HTTP/HTTP same-port listeners"
      else
        fail "MCP Gateway same-port topology is missing an admitted OpenShift edge TLS Route"
      fi
    elif [[ "${listener_protocol}" == "HTTPS" ]]; then
      pass "Gateway/${GATEKEEPER_GATEWAY_NAME} uses HTTPS"
    else
      fail "Gateway/${GATEKEEPER_GATEWAY_NAME} is not configured for HTTPS"
    fi
  fi

  if [[ "${GATEKEEPER_LANE}" == "production" ]]; then
    local auth_json
    auth_json="$(oc get authpolicy "${GATEKEEPER_AUTH_POLICY_NAME}" -n "${GATEKEEPER_GATEWAY_NAMESPACE}" -o json 2>/dev/null || true)"
    auth_conditions="$(printf '%s' "${auth_json}" | json_value "[(c.get('type'),c.get('status')) for c in x.get('status',{}).get('conditions',[])]")"
    if [[ "${GATEKEEPER_AUTH_MODE}" == "tokenreview" &&
      "${auth_conditions}" == *"('Accepted', 'True')"* &&
      "${auth_conditions}" == *"('Enforced', 'True')"* ]] &&
      auth_policy_uses_tokenreview "${auth_json}"; then
      pass "OpenShift TokenReview AuthPolicy/${GATEKEEPER_AUTH_POLICY_NAME}: Accepted=True, Enforced=True"
    elif [[ "${GATEKEEPER_AUTH_MODE}" == "oidc" && -n "${GATEKEEPER_OIDC_ISSUER}" &&
      "${auth_conditions}" == *"('Accepted', 'True')"* &&
      "${auth_conditions}" == *"('Enforced', 'True')"* ]] &&
      auth_policy_matches_oidc_issuer "${auth_json}"; then
      pass "native OIDC AuthPolicy/${GATEKEEPER_AUTH_POLICY_NAME}: Accepted=True, Enforced=True, configured issuer matches"
    elif [[ -n "${auth_json}" && "${auth_conditions}" == *"('Accepted', 'True')"* && "${auth_conditions}" == *"('Enforced', 'True')"* ]]; then
      fail "AuthPolicy/${GATEKEEPER_AUTH_POLICY_NAME} is enforced, but it does not match GATEKEEPER_AUTH_MODE=${GATEKEEPER_AUTH_MODE}"
    else
      fail "AuthPolicy/${GATEKEEPER_AUTH_POLICY_NAME} is not Accepted and Enforced for GATEKEEPER_AUTH_MODE=${GATEKEEPER_AUTH_MODE}"
    fi
  fi

  record_metadata preflight
  log "Preflight result: failures=${FAILURES}, warnings=${WARNINGS}"
  # Preview is allowed to carry Technology Preview/support warnings, but it
  # must still fail when the selected runtime does not satisfy its pinned
  # source, topology, security, or protocol contract.
  if [[ ${FAILURES} -gt 0 ]]; then return 1; fi
  return 0
}

apply_network_policy() {
  local source="${ARAMCO_ROOT}/hardening/networkpolicy-backend-lockdown.yaml"
  [[ -f "${source}" ]] || { fail "NetworkPolicy reference artifact missing"; return; }
  oc apply -f "${source}" | tee -a "${REPORT}"
  if backend_isolation_is_ready; then
    pass "effective backend isolation is enforced"
  else
    warn "Gatekeeper backend NetworkPolicy was applied, but the operator-reconciled policy still permits all ingress; the layer is not production-ready"
  fi
}

apply_native_auth() {
  [[ -n "${GATEKEEPER_OIDC_ISSUER}" ]] || { fail "native AuthPolicy requested without GATEKEEPER_OIDC_ISSUER"; return; }
  local source="${ARAMCO_ROOT}/hardening/authpolicy-oidc.yaml"
  local rendered="${RUN_DIR}/authpolicy-oidc.yaml"
  python3 - "${source}" "${rendered}" "${GATEKEEPER_OIDC_ISSUER}" "${GATEKEEPER_OIDC_JWKS_URL}" <<'PY'
import pathlib, sys
source, target, issuer, jwks_url = sys.argv[1:]
text = pathlib.Path(source).read_text()
text = text.replace("https://REPLACE-keycloak-host/realms/REPLACE-realm", issuer)
if jwks_url:
    text = text.replace(f"issuerUrl: {issuer}", f"jwksUrl: {jwks_url}\n            issuer: {issuer}")
pathlib.Path(target).write_text(text)
PY
  if [[ -n "${GATEKEEPER_OIDC_JWKS_URL}" ]]; then
    log "OIDC key retrieval configured through the cluster-local JWKS endpoint"
  fi
  oc apply -f "${rendered}" | tee -a "${REPORT}"
  pass "native OIDC AuthPolicy applied with configured issuer"
}

apply_tokenreview_auth() {
  local source="${HERE}/manifests/authpolicy-tokenreview.yaml"
  [[ -f "${source}" ]] || { fail "OpenShift TokenReview AuthPolicy manifest missing"; return; }
  oc apply -f "${source}" | tee -a "${REPORT}"
  pass "OpenShift-native TokenReview AuthPolicy applied"
}

apply_internal_authz() {
  [[ "${GATEKEEPER_ENABLE_INTERNAL_AUTHZ}" == "1" ]] || {
    log "internal ${GATEKEEPER_INTERNAL_LISTENER_NAME} AuthPolicy reconciliation disabled by profile"
    return 0
  }
  local source="${HERE}/manifests/authpolicy-tokenreview-mcps.yaml" rendered
  rendered="${RUN_DIR}/authpolicy-${GATEKEEPER_INTERNAL_LISTENER_NAME}.yaml"
  [[ -f "${source}" ]] || { fail "internal listener AuthPolicy manifest missing: ${source}"; return; }
  python3 - "${source}" "${rendered}" "${GATEKEEPER_GATEWAY_NAMESPACE}" "${GATEKEEPER_GATEWAY_NAME}" "${GATEKEEPER_INTERNAL_AUTH_POLICY_NAME}" "${GATEKEEPER_INTERNAL_LISTENER_NAME}" <<'PY'
import pathlib, sys
source, target, namespace, gateway, policy, section = sys.argv[1:]
text = pathlib.Path(source).read_text()
text = text.replace("name: mcps-auth-policy", f"name: {policy}")
text = text.replace("namespace: mcp-gateway-system", f"namespace: {namespace}")
text = text.replace("name: mcp-gateway\n    sectionName: mcps", f"name: {gateway}\n    sectionName: {section}")
pathlib.Path(target).write_text(text)
PY
  oc apply -f "${rendered}" | tee -a "${REPORT}"
  pass "OpenShift-native internal ${GATEKEEPER_INTERNAL_LISTENER_NAME} AuthPolicy applied"
}

backend_bypass_probe() {
  local probe_name="gatekeeper-bypass-probe-${RUN_ID,,}"
  local raw status

  # `oc run --rm -i` appends a deletion message to stdout. Parse the explicit
  # status when available and treat deletion without a status as a blocked
  # connection; a reachable backend always emits a three-digit HTTP status.
  raw="$(oc run "${probe_name}" --rm -i --restart=Never -n default \
    --image=registry.access.redhat.com/ubi9/ubi-minimal \
    --command -- sh -c 'code=$(curl -s -m 5 -o /dev/null -w "%{http_code}" "http://mempalace.mempalace.svc.cluster.local:8000/health"); rc=$?; if [ "$rc" -ne 0 ]; then code=000; fi; printf "GATEKEEPER_HTTP_STATUS:%s\\n" "$code"' \
    2>/dev/null || true)"
  status="$(printf '%s' "${raw}" | sed -n 's/.*GATEKEEPER_HTTP_STATUS:\([0-9][0-9][0-9]\).*/\1/p' | tail -1)"
  if [[ -z "${status}" && "${raw}" == *deleted* ]]; then status=000; fi
  printf '%s' "${status:-UNKNOWN}"
}

oc_json_or() {
  local empty_value="$1"
  shift
  local value
  value="$(oc "$@" -o json 2>/dev/null || true)"
  if [[ -n "${value}" ]]; then
    printf '%s' "${value}"
  else
    printf '%s' "${empty_value}"
  fi
}

operator_csv_inventory() {
  local csvs='{"items":[]}' namespace namespace_csv
  local -a namespaces
  IFS=',' read -r -a namespaces <<<"${GATEKEEPER_OPERATOR_NAMESPACES}"
  for namespace in "${namespaces[@]}"; do
    namespace="${namespace//[[:space:]]/}"
    [[ -n "${namespace}" ]] || continue
    namespace_csv="$(oc_json_or '{"items":[]}' get csv -n "${namespace}")"
    csvs="$(printf '%s\n%s\n' "${csvs}" "${namespace_csv}" | jq -s -c '{items: map(.items // []) | add}')"
  done
  printf '%s' "${csvs}"
}

upgrade_snapshot() {
  local target="$1"
  local cluster_version subscriptions csvs installplans datascienceclusters
  local rhoai_subscriptions rhoai_csvs layer_csvs installplan_state dsc_state
  local crd_inventory='{}'

  cluster_version="$(oc_json_or '{}' get clusterversion version)"
  subscriptions="$(oc_json_or '{"items":[]}' get subscriptions -A)"
  csvs="$(operator_csv_inventory)"
  installplans="$(oc_json_or '{"items":[]}' get installplans -A)"
  datascienceclusters="$(oc_json_or '{"items":[]}' get datascienceclusters -A)"

  rhoai_subscriptions="$(jq -c '[.items[]? | select((.spec.name // "" | test("rhods|rhoai|red hat openshift ai"; "i")) or (.metadata.name // "" | test("rhods|rhoai|red hat openshift ai"; "i"))) | {namespace:.metadata.namespace,name:.metadata.name,package:.spec.name,channel:.spec.channel,installPlanApproval:.spec.installPlanApproval,startingCSV:.spec.startingCSV}]' <<<"${subscriptions}" 2>/dev/null || echo '[]')"
  rhoai_csvs="$(jq -c '[.items[]? | select((.spec.displayName // "" | test("red hat openshift ai|rhods|rhoai"; "i")) or (.spec.name // "" | test("rhods|rhoai"; "i")) or (.metadata.name // "" | test("rhods|rhoai"; "i"))) | {namespace:.metadata.namespace,name:.metadata.name,version:.spec.version,phase:.status.phase,reason:.status.reason}]' <<<"${csvs}" 2>/dev/null || echo '[]')"
  layer_csvs="$(jq -c '[.items[]? | select((.metadata.name // "" | test("mcp-gateway|kuadrant|authorino|limitador|servicemesh|sailoperator"; "i")) or (.spec.displayName // "" | test("mcp gateway|kuadrant|authorino|limitador|service mesh|sail operator"; "i"))) | {namespace:.metadata.namespace,name:.metadata.name,version:.spec.version,phase:.status.phase,reason:.status.reason,channel:(.metadata.annotations["olm.operatorGroup"] // "")}]' <<<"${csvs}" 2>/dev/null || echo '[]')"
  installplan_state="$(jq -c '[.items[]? | {namespace:.metadata.namespace,name:.metadata.name,phase:.status.phase,approved:.spec.approved,approval:.spec.installPlanApproval}]' <<<"${installplans}" 2>/dev/null || echo '[]')"
  dsc_state="$(jq -c '[.items[]? | {namespace:.metadata.namespace,name:.metadata.name,phase:.status.phase,conditions:.status.conditions}]' <<<"${datascienceclusters}" 2>/dev/null || echo '[]')"

  local crd
  for crd in \
    datascienceclusters.datasciencecluster.opendatahub.io \
    subscriptions.operators.coreos.com \
    clusterserviceversions.operators.coreos.com \
    gateways.gateway.networking.k8s.io \
    httproutes.gateway.networking.k8s.io \
    authpolicies.kuadrant.io \
    mcpserverregistrations.mcp.kuadrant.io \
    adminnetworkpolicies.policy.networking.k8s.io; do
    local crd_json crd_summary
    crd_json="$(oc_json_or '{}' get crd "${crd}")"
    crd_summary="$(jq -c '{name:.metadata.name,resourceVersion:.metadata.resourceVersion,versions:[.spec.versions[]? | {name,served,storage}]}' <<<"${crd_json}" 2>/dev/null || echo '{}')"
    crd_inventory="$(jq -c --arg name "${crd}" --argjson value "${crd_summary}" '. + {($name): $value}' <<<"${crd_inventory}")"
  done

  mkdir -p "$(dirname "${target}")"
  jq -n \
    --arg capturedAt "$(timestamp)" \
    --arg gatekeeperCatalog "${GATEKEEPER_CATALOG_VERSION}" \
    --arg gatekeeperProfile "${GATEKEEPER_PROFILE}" \
    --argjson clusterVersion "${cluster_version}" \
    --argjson rhoaiSubscriptions "${rhoai_subscriptions}" \
    --argjson rhoaiCsvs "${rhoai_csvs}" \
    --argjson layerCsvs "${layer_csvs}" \
    --argjson installPlans "${installplan_state}" \
    --argjson dataScienceClusters "${dsc_state}" \
    --argjson crds "${crd_inventory}" \
    '{schemaVersion:"project-matrix.upgrade/v1alpha1",capturedAt:$capturedAt,gatekeeper:{catalog:$gatekeeperCatalog,profile:$gatekeeperProfile},openShift:{version:(($clusterVersion.status.desired.version // $clusterVersion.status.desired.image // "unknown")),channel:($clusterVersion.spec.channel // "unknown"),clusterVersion:$clusterVersion.status.desired},openShiftAI:{subscriptions:$rhoaiSubscriptions,csvs:$rhoaiCsvs,dataScienceClusters:$dataScienceClusters},layerOperators:$layerCsvs,installPlans:$installPlans,crds:$crds}' \
    >"${target}"
}

upgrade_stability_gate() {
  local installplans csvs dsc cluster_operators pending_plans approval_plans failed_csvs
  installplans="$(oc_json_or '{"items":[]}' get installplans -A)"
  pending_plans="$(jq -r '[.items[]? | select((.status.phase // "") | test("Installing|Pending"; "i")) | [.metadata.namespace,.metadata.name,.status.phase] | @tsv] | .[]' <<<"${installplans}" 2>/dev/null || true)"
  if [[ -n "${pending_plans}" ]]; then
    printf '%s\n' "${pending_plans}" | sed 's/^/  /' | tee -a "${REPORT}" >/dev/null
    fail "OLM has InstallPlans in an active transition; defer upgrade post-check until OLM is stable"
  else
    pass "OLM InstallPlans have no pending or installing transitions"
  fi
  approval_plans="$(jq -r '[.items[]? | select((.status.phase // "") == "RequiresApproval") | [.metadata.namespace,.metadata.name,.status.phase] | @tsv] | .[]' <<<"${installplans}" 2>/dev/null || true)"
  if [[ -n "${approval_plans}" ]]; then
    printf '%s\n' "${approval_plans}" | sed 's/^/  /' | tee -a "${REPORT}" >/dev/null
    warn "OLM has manual-approval InstallPlans available; Gatekeeper will not approve them, and the customer may remain on the current certified release"
  fi

  csvs="$(operator_csv_inventory)"
  failed_csvs="$(jq -r '[.items[]? | select(((.status.phase // "") | test("Failed|Replacing"; "i")) and ((.status.reason // "") != "UnsupportedOperatorGroup") and ((.status.reason // "") != "Copied")) | [.metadata.namespace,.metadata.name,.status.phase,.status.reason] | @tsv] | .[]' <<<"${csvs}" 2>/dev/null || true)"
  if [[ -n "${failed_csvs}" ]]; then
    printf '%s\n' "${failed_csvs}" | sed 's/^/  /' | tee -a "${REPORT}" >/dev/null
    fail "one or more ClusterServiceVersions are Failed or Replacing"
  else
    pass "ClusterServiceVersions have no Failed or Replacing entries"
  fi

  dsc="$(oc_json_or '{"items":[]}' get datascienceclusters -A)"
  if [[ "$(jq -r '[.items[]? | select((.status.phase // "") != "Ready")] | length' <<<"${dsc}" 2>/dev/null || echo 1)" == "0" ]]; then
    pass "all discovered OpenShift AI DataScienceClusters are Ready"
  else
    fail "one or more OpenShift AI DataScienceClusters are not Ready"
  fi

  cluster_operators="$(oc_json_or '{"items":[]}' get clusteroperators)"
  if [[ "$(jq -r '[.items[]? | .status.conditions[]? | select((.type == "Available" and .status != "True") or (.type == "Degraded" and .status == "True") or (.type == "Progressing" and .status == "True"))] | length' <<<"${cluster_operators}" 2>/dev/null || echo 1)" == "0" ]]; then
    pass "all ClusterOperators report stable Available/Degraded/Progressing conditions"
  else
    fail "one or more ClusterOperators are unavailable, degraded, or progressing"
  fi
}

upgrade_preflight() {
  oc_required
  begin_report
  section "Upgrade preflight"
  log "Upgrade ownership: OpenShift and OpenShift AI/OLM; Gatekeeper is read-only"
  log "Baseline output: ${UPGRADE_BASELINE}"
  upgrade_snapshot "${UPGRADE_BASELINE}"
  pass "OpenShift, OpenShift AI, operator, API, and layer baseline captured"
  upgrade_stability_gate
  if preflight; then
    pass "current ${GATEKEEPER_LANE} lane passed before upgrade"
  else
    fail "current ${GATEKEEPER_LANE} lane is not eligible for an upgrade-certified baseline"
  fi
  log "Upgrade preflight does not approve, execute, or roll back an OpenShift AI upgrade"
  record_metadata upgrade-preflight
  log "Upgrade preflight result: failures=${FAILURES}, warnings=${WARNINGS}"
  [[ ${FAILURES} -eq 0 ]]
}

upgrade_postcheck() {
  oc_required
  begin_report
  section "Upgrade post-check"
  if [[ ! -s "${UPGRADE_BASELINE}" ]]; then
    fail "upgrade baseline is missing: ${UPGRADE_BASELINE}; run upgrade-preflight before the platform upgrade"
  else
    local current_snapshot
    current_snapshot="${RUN_DIR}/upgrade-postcheck.json"
    upgrade_snapshot "${current_snapshot}"
    python3 - "${UPGRADE_BASELINE}" "${current_snapshot}" <<'PY' | tee -a "${REPORT}"
import json, sys
before_path, after_path = sys.argv[1:]
before = json.load(open(before_path))
after = json.load(open(after_path))
before_version = before.get("openShift", {}).get("version", "unknown")
after_version = after.get("openShift", {}).get("version", "unknown")
print(f"OpenShift baseline/current: {before_version} -> {after_version}")
before_csv = {(x.get("namespace"), x.get("name")): (x.get("version"), x.get("phase")) for x in before.get("openShiftAI", {}).get("csvs", []) + before.get("layerOperators", [])}
after_csv = {(x.get("namespace"), x.get("name")): (x.get("version"), x.get("phase")) for x in after.get("openShiftAI", {}).get("csvs", []) + after.get("layerOperators", [])}
for key in sorted(set(before_csv) | set(after_csv)):
    if before_csv.get(key) != after_csv.get(key):
        print(f"Operator transition: {key[0]}/{key[1]} {before_csv.get(key)} -> {after_csv.get(key)}")
before_crds = before.get("crds", {})
after_crds = after.get("crds", {})
for name in sorted(set(before_crds) | set(after_crds)):
    old = before_crds.get(name, {}).get("versions", [])
    new = after_crds.get(name, {}).get("versions", [])
    if old != new:
        print(f"CRD version transition: {name} {old} -> {new}")
PY
    pass "post-upgrade inventory captured and compared with the baseline"
  fi
  upgrade_stability_gate
  if preflight; then
    pass "current ${GATEKEEPER_LANE} lane passed after upgrade"
  else
    fail "current ${GATEKEEPER_LANE} lane requires remediation after upgrade"
  fi
  if validate; then
    pass "Gateway validation passed after upgrade"
  else
    fail "Gateway validation failed after upgrade"
  fi
  log "Post-check is the promotion gate; it does not perform rollback"
  record_metadata upgrade-postcheck
  log "Upgrade post-check result: failures=${FAILURES}, warnings=${WARNINGS}"
  [[ ${FAILURES} -eq 0 ]]
}

install() {
  oc_required
  begin_report
  section "Install"
  if ! preflight; then
    if [[ "${GATEKEEPER_LANE}" == "production" ]]; then
      fail "installation stopped by production preflight gate"
      record_metadata blocked
      return 1
    fi
  fi
  if oc get namespace matrix-system >/dev/null 2>&1; then
    pass "namespace matrix-system already exists; no namespace mutation required"
  else
    oc apply -f "${HERE}/manifests/matrix-system.yaml" | tee -a "${REPORT}"
  fi
  oc create configmap gatekeeper-layer-deployment -n matrix-system \
    --from-literal=layer=Gateway \
    --from-literal=codeName=Gatekeeper \
    --from-literal=lane="${GATEKEEPER_LANE}" \
    --from-literal=profile="${GATEKEEPER_PROFILE}" \
    --from-literal=phase=Installed \
    --from-literal=createdAt="$(timestamp)" \
    --dry-run=client -o yaml | oc apply -f - | tee -a "${REPORT}"
  pass "Gatekeeper deployment record created in matrix-system"

  if [[ "${GATEKEEPER_APPLY_NETWORK_POLICY}" == "1" ]]; then apply_network_policy; else warn "backend NetworkPolicy disabled by profile"; fi
  ensure_gateway_tls
  ensure_gateway_dns
  if [[ "${GATEKEEPER_ENABLE_NATIVE_AUTH}" == "1" ]]; then
    case "${GATEKEEPER_AUTH_MODE}" in
      tokenreview) apply_tokenreview_auth ;;
      oidc) apply_native_auth ;;
      *) fail "unsupported GATEKEEPER_AUTH_MODE=${GATEKEEPER_AUTH_MODE}; AuthPolicy was not applied" ;;
    esac
  else
    warn "AuthPolicy mutation disabled by the selected innovation profile"
  fi
  apply_internal_authz
  if [[ "${GATEKEEPER_INSTALL_FIXTURES}" == "1" ]]; then
    oc apply -f "${ARAMCO_ROOT}/hardening/openshift-mcp-server.yaml" | tee -a "${REPORT}"
    pass "read-only OpenShift MCP evaluation fixture applied"
  else
    log "evaluation fixtures left unchanged; set GATEKEEPER_INSTALL_FIXTURES=1 to install them"
  fi
  record_metadata installed
  log "Install result: failures=${FAILURES}, warnings=${WARNINGS}"
  [[ ${FAILURES} -eq 0 ]]
}

validate() {
  oc_required
  begin_report
  section "Validate"
  check_gateway_status
  check_gateway_extension_contract
  if oc get mcpserverregistration -n "${GATEKEEPER_GATEWAY_NAMESPACE}" >/dev/null 2>&1; then
    oc get mcpserverregistration -n "${GATEKEEPER_GATEWAY_NAMESPACE}" -o wide | tee -a "${REPORT}"
    pass "MCP server registrations are queryable"
  else
    fail "MCPServerRegistration resources are unavailable"
  fi
  if oc get networkpolicy mempalace-allow-gateway-only -n "${GATEKEEPER_BACKEND_NAMESPACE}" >/dev/null 2>&1; then pass "backend bypass backstop resource is present"; else warn "backend bypass backstop is not installed"; fi

  if [[ -n "${GATEKEEPER_MCP_URL}" ]]; then
    local code
    code="$(curl -ksS -o /dev/null -w '%{http_code}' -m 20 -X POST "${GATEKEEPER_MCP_URL}" -H 'Content-Type: application/json' -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}' || true)"
    log "Unauthenticated MCP endpoint: $(redact_url "${GATEKEEPER_MCP_URL}") -> HTTP ${code}"
    if [[ "${code}" == "401" ]]; then
      pass "unauthenticated MCP traffic rejected"
    elif [[ "${GATEKEEPER_LANE}" == "production" ]]; then
      if [[ "${code}" == "503" ]]; then
        fail "MCP edge returned HTTP 503; public Gateway exposure is unavailable"
      else
        fail "MCP edge returned HTTP ${code}; Production requires the standard unauthenticated HTTP 401 challenge"
      fi
    else
      warn "expected HTTP 401 from secured edge, received ${code}"
    fi
    if [[ -n "${GATEKEEPER_BEARER_TOKEN:-}" ]]; then
      local response_file headers_file session_id initialize_payload list_payload call_payload tools_count
      response_file="$(mktemp "${RUN_DIR}/mcp-response.XXXXXX")"
      headers_file="$(mktemp "${RUN_DIR}/mcp-headers.XXXXXX")"
      initialize_payload='{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-03-26","capabilities":{},"clientInfo":{"name":"gatekeeper-validator","version":"1.0"}}}'
      code="$(curl -ksS -D "${headers_file}" -o "${response_file}" -w '%{http_code}' -m 20 -X POST "${GATEKEEPER_MCP_URL}" -H "Authorization: Bearer ${GATEKEEPER_BEARER_TOKEN}" -H 'Content-Type: application/json' -d "${initialize_payload}" || true)"
      mcp_normalize_response "${response_file}"
      session_id="$(awk 'BEGIN {IGNORECASE=1} /^mcp-session-id:/ {sub(/\r$/, ""); sub(/^[^:]*:[[:space:]]*/, ""); print; exit}' "${headers_file}")"
      log "Authenticated MCP endpoint -> HTTP ${code}; session_present=$([[ -n "${session_id}" ]] && echo true || echo false)"
      if [[ "${code}" == "200" ]] && [[ -n "${session_id}" ]] && jq -e '.jsonrpc == "2.0" and (.result | type == "object")' "${response_file}" >/dev/null 2>&1; then
        pass "authenticated MCP initialize accepted"
      else
        fail "authenticated MCP initialize failed with HTTP ${code}, missing session, or invalid JSON-RPC response"
      fi

      list_payload='{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}'
      code="$(curl -ksS -o "${response_file}" -w '%{http_code}' -m 20 -X POST "${GATEKEEPER_MCP_URL}" -H "Authorization: Bearer ${GATEKEEPER_BEARER_TOKEN}" -H "Mcp-Session-Id: ${session_id}" -H 'Content-Type: application/json' -d "${list_payload}" || true)"
      mcp_normalize_response "${response_file}"
      tools_count="$(jq -r 'if (.jsonrpc == "2.0" and (.result.tools | type) == "array") then (.result.tools | length) else -1 end' "${response_file}" 2>/dev/null || echo -1)"
      if [[ "${code}" == "200" && "${tools_count}" =~ ^[0-9]+$ && "${tools_count}" -ge 0 ]]; then
        pass "authenticated MCP tools/list accepted (${tools_count} tools)"
      else
        fail "authenticated MCP tools/list failed with HTTP ${code} or invalid tool inventory"
      fi

      if [[ -n "${GATEKEEPER_MCP_TOOL_NAME}" ]]; then
        if ! jq -e . >/dev/null 2>&1 <<<"${GATEKEEPER_MCP_TOOL_ARGUMENTS_JSON}"; then
          fail "GATEKEEPER_MCP_TOOL_ARGUMENTS_JSON is not valid JSON"
        else
          call_payload="$(jq -cn --arg name "${GATEKEEPER_MCP_TOOL_NAME}" --argjson arguments "${GATEKEEPER_MCP_TOOL_ARGUMENTS_JSON}" '{jsonrpc:"2.0",id:3,method:"tools/call",params:{name:$name,arguments:$arguments}}')"
          code="$(curl -ksS -o "${response_file}" -w '%{http_code}' -m 30 -X POST "${GATEKEEPER_MCP_URL}" -H "Authorization: Bearer ${GATEKEEPER_BEARER_TOKEN}" -H "Mcp-Session-Id: ${session_id}" -H 'Content-Type: application/json' -d "${call_payload}" || true)"
          mcp_normalize_response "${response_file}"
          if [[ "${code}" == "200" ]] && jq -e '.jsonrpc == "2.0" and (.result | type == "object") and (.result.isError != true)' "${response_file}" >/dev/null 2>&1; then
            pass "authenticated MCP tools/call accepted for ${GATEKEEPER_MCP_TOOL_NAME}"
          else
            fail "authenticated MCP tools/call failed for ${GATEKEEPER_MCP_TOOL_NAME} with HTTP ${code}"
          fi
        fi
      else
        warn "authenticated MCP tools/call skipped; set GATEKEEPER_MCP_TOOL_NAME and GATEKEEPER_MCP_TOOL_ARGUMENTS_JSON to run an approved non-destructive call"
      fi
      rm -f "${response_file}" "${headers_file}"
    else
      warn "positive authenticated MCP initialize/tools-list/tools-call tests skipped; GATEKEEPER_BEARER_TOKEN is not set and is never written to evidence"
    fi
  else
    warn "MCP endpoint not configured; protocol smoke tests skipped"
  fi

  if [[ "${GATEKEEPER_CONFIRM_NETWORK_PROBE}" == "1" ]]; then
    log "Running explicit in-cluster backend bypass probe"
    probe="$(backend_bypass_probe)"
    log "Direct backend probe result: ${probe}"
    [[ "${probe}" == "000" ]] && pass "direct backend access is blocked" || fail "direct backend access remains reachable or probe was inconclusive"
  else
    warn "direct backend probe skipped; set GATEKEEPER_CONFIRM_NETWORK_PROBE=1 to create a temporary probe pod"
  fi
  record_metadata validated
  log "Validation result: failures=${FAILURES}, warnings=${WARNINGS}"
  [[ ${FAILURES} -eq 0 ]]
}

evaluate() {
  oc_required
  begin_report
  section "Evaluate"
  if [[ "${GATEKEEPER_RUN_ARAMOCK_CONFORMANCE}" == "1" ]]; then
    local aramock_status=0
    bash "${HERE}/conformance/aramock-gateway.sh" 2>&1 | tee -a "${REPORT}" || aramock_status=$?
    case "${aramock_status}" in
      0) pass "Aramock-derived Gateway conformance passed" ;;
      10) warn "Aramock fixture is not fully present; conformance remains advisory" ;;
      *) fail "Aramock-derived Gateway conformance failed" ;;
    esac
  else
    log "Aramock-derived conformance is disabled for this profile"
  fi
  if [[ "${GATEKEEPER_ROUNDTRIP}" != "1" ]]; then
    warn "live MCP-to-MaaS evaluation not selected; set GATEKEEPER_ROUNDTRIP=1"
    log "Reference task: Summarize the current MCP gateway architecture using live cluster and memory observations."
    record_metadata evaluated
    return 0
  fi
  [[ -n "${GATEKEEPER_MCP_URL}" ]] || { fail "GATEKEEPER_MCP_URL is required for the live round trip"; return 1; }
  log "Launching the inspectable Saudi Aramco MCP-to-MaaS round trip"
  GATEKEEPER_MCP_URL="${GATEKEEPER_MCP_URL}" \
  MCP_KEYCLOAK_BASE_URL="${GATEKEEPER_OIDC_ISSUER%/realms/*}" \
  GATEKEEPER_MAAS_URL="${GATEKEEPER_MAAS_URL}" \
  GATEKEEPER_MODEL="${GATEKEEPER_MODEL}" \
    bash "${ARAMCO_ROOT}/maas-mcp-roundtrip/run.sh" | tee -a "${REPORT}"
  pass "live MCP-to-MaaS reference evaluation completed"
  record_metadata evaluated
}

diagnostics() {
  oc_required
  section "Diagnostics"
  local out="${RUN_DIR}/cluster-diagnostics.txt"
  {
    echo "Project Matrix Gatekeeper diagnostics $(timestamp)"
    echo "Lane=${GATEKEEPER_LANE} Profile=${GATEKEEPER_PROFILE}"
    echo; echo "== ClusterOperators =="; oc get co
    echo; echo "== Gatekeeper and Gateway namespaces =="; oc get pods -n matrix-system -o wide 2>&1 || true; oc get pods -n "${GATEKEEPER_GATEWAY_NAMESPACE}" -o wide 2>&1 || true
    echo; echo "== Gateway resources =="; oc get gateway,httproute -A 2>&1 || true
    echo; echo "== MCP registrations =="; oc get mcpserverregistration -A -o wide 2>&1 || true
    echo; echo "== Recent events =="; oc get events -A --sort-by=.lastTimestamp 2>&1 | tail -80 || true
  } >"${out}"
  log "Diagnostics bundle: ${out}"
  record_metadata diagnostics
}

usage() {
  cat <<EOF
Usage: $0 [--profile production|innovation] <preflight|install|validate|evaluate|diagnostics|upgrade-preflight|upgrade-postcheck|all>

Examples:
  $0 all                              # Production is the safe default
  $0 --profile innovation all         # Explicit Preview/innovation lane
  GATEKEEPER_MCP_URL=https://gateway.example/mcp $0 --profile innovation validate
  GATEKEEPER_OIDC_ISSUER=https://id.example/realms/mcp $0 --profile production preflight
  $0 --profile production upgrade-preflight
  GATEKEEPER_UPGRADE_BASELINE=/path/to/baseline.json $0 --profile production upgrade-postcheck

The current run evidence is written under .gatekeeper-runs/ and is gitignored.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile) PROFILE_NAME="$2"; PROFILE_FILE="${HERE}/profiles/${PROFILE_NAME}.env"; [[ -f "${PROFILE_FILE}" ]] || { echo "unknown profile: $PROFILE_NAME" >&2; exit 2; }; source "${PROFILE_FILE}"; shift 2;;
    -h|--help) usage; exit 0;;
    *) break;;
  esac
done

# Re-load after parsing --profile so the selected lane/profile pair is the one
# recorded in evidence and validated before any cluster command can run.
load_profile_contract

COMMAND="${1:-all}"
case "${COMMAND}" in
  preflight) preflight;;
  install) install;;
  validate) validate;;
  evaluate) evaluate;;
  diagnostics) diagnostics;;
  upgrade-preflight) upgrade_preflight;;
  upgrade-postcheck) upgrade_postcheck;;
  all)
    all_status=0
    if preflight; then
      install || all_status=1
      validate || all_status=1
      evaluate || all_status=1
    else
      all_status=1
      log "Install and evaluation skipped because the selected lane failed preflight"
    fi
    diagnostics || all_status=1
    exit "${all_status}"
    ;;
  *) usage; exit 2;;
esac

log "Evidence directory: ${RUN_DIR}"
