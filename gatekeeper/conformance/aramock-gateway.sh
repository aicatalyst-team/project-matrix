#!/usr/bin/env bash
# Read-only Aramock-derived Gateway/MaaS conformance check.
#
# This deliberately does not bootstrap Aramock, provision GPUs, create
# namespaces, change MaaS, or change cluster/network policy. The full Aramock
# setup remains an external Bedrock/test-fixture operation owned by its team.
set -euo pipefail

MODEL_NAMESPACE="${GATEKEEPER_ARAMOCK_MODEL_NAMESPACE:-aramock-models}"
MODEL_NAME="${GATEKEEPER_ARAMOCK_MODEL_NAME:-aramock-simulator}"
MAAS_NAMESPACE="${GATEKEEPER_ARAMOCK_MAAS_NAMESPACE:-models-as-a-service}"
MODEL_REF_NAME="${GATEKEEPER_ARAMOCK_MODEL_REF_NAME:-${MODEL_NAME}}"
AUTH_POLICY_NAME="${GATEKEEPER_ARAMOCK_AUTH_POLICY_NAME:-aramock-simulator-access}"
SUBSCRIPTION_NAME="${GATEKEEPER_ARAMOCK_SUBSCRIPTION_NAME:-aramock-simulator-free}"

command -v oc >/dev/null 2>&1 || { echo "FAIL: oc is required" >&2; exit 2; }
command -v jq >/dev/null 2>&1 || { echo "FAIL: jq is required" >&2; exit 2; }
oc whoami >/dev/null 2>&1 || { echo "FAIL: no active oc session" >&2; exit 2; }

pass() { printf 'PASS: %s\n' "$*"; }
fail() { printf 'FAIL: %s\n' "$*"; FAILURES=$((FAILURES + 1)); }
warn() { printf 'WARN: %s\n' "$*"; WARNINGS=$((WARNINGS + 1)); }

FAILURES=0
WARNINGS=0

resource_json() {
  local resource="$1" name="$2" namespace="$3"
  oc get "$resource" "$name" -n "$namespace" -o json 2>/dev/null
}

check_exists() {
  local resource="$1" name="$2" namespace="$3" label="$4"
  local object
  if ! object="$(resource_json "$resource" "$name" "$namespace")"; then
    fail "$label is missing: $resource/$name in $namespace"
    return 1
  fi
  local owner_label
  owner_label="$(jq -r '.metadata.labels["workflow-validation.redhat.com/aramock"] // ""' <<<"$object")"
  if [[ "$owner_label" == "true" ]]; then
    pass "$label exists and is Aramock-labelled"
  else
    warn "$label exists but is not Aramock-labelled; ownership must be reviewed"
  fi
  return 0
}

check_condition() {
  local object="$1" condition_type="$2" label="$3"
  if jq -e --arg type "$condition_type" \
    'any(.status.conditions[]?; .type == $type and .status == "True")' \
    <<<"$object" >/dev/null; then
    pass "$label: $condition_type=True"
  else
    local conditions
    conditions="$(jq -c '.status.conditions // []' <<<"$object")"
    fail "$label is not $condition_type=True: $conditions"
  fi
}

printf 'Aramock Gateway conformance (read-only)\n'
printf 'Model: %s/%s\n' "$MODEL_NAMESPACE" "$MODEL_NAME"
printf 'MaaS governance: %s/%s\n' "$MAAS_NAMESPACE" "$SUBSCRIPTION_NAME"

# The fixture is optional for the innovation profile. If none of its marker
# resources exists, report an advisory skip rather than turning an otherwise
# valid Gatekeeper evaluation into a failure. Once any marker exists, partial or
# unhealthy fixture state is actionable and is checked strictly below.
fixture_marker=0
for marker in \
  "llminferenceservice|${MODEL_NAME}|${MODEL_NAMESPACE}" \
  "maasmodelref|${MODEL_REF_NAME}|${MODEL_NAMESPACE}" \
  "maasauthpolicy|${AUTH_POLICY_NAME}|${MAAS_NAMESPACE}" \
  "maassubscription|${SUBSCRIPTION_NAME}|${MAAS_NAMESPACE}"; do
  IFS='|' read -r resource name namespace <<<"$marker"
  if oc get "$resource" "$name" -n "$namespace" >/dev/null 2>&1; then
    fixture_marker=1
    break
  fi
done
if (( fixture_marker == 0 )); then
  warn "Aramock fixture is not installed; no fixture resources were changed or created"
  printf 'Aramock conformance result: failures=0 warnings=%s\n' "$WARNINGS"
  exit 10
fi

if ! oc get crd llminferenceservices.serving.kserve.io >/dev/null 2>&1; then
  fail "LLMInferenceService CRD is missing"
fi
if ! oc get crd maasmodelrefs.maas.opendatahub.io >/dev/null 2>&1; then
  fail "MaaSModelRef CRD is missing"
fi
if ! oc get crd maasauthpolicies.maas.opendatahub.io >/dev/null 2>&1; then
  fail "MaaSAuthPolicy CRD is missing"
fi
if ! oc get crd maassubscriptions.maas.opendatahub.io >/dev/null 2>&1; then
  fail "MaaSSubscription CRD is missing"
fi

gateway="$(resource_json gateway maas-default-gateway openshift-ingress || true)"
if [[ -z "$gateway" ]]; then
  fail "MaaS Gateway is missing: openshift-ingress/maas-default-gateway"
else
  if jq -e 'any(.status.conditions[]?; .type == "Accepted" and .status == "True")' <<<"$gateway" >/dev/null; then
    pass "MaaS Gateway Accepted=True"
  else
    fail "MaaS Gateway is not Accepted=True"
  fi
  if jq -e 'any(.status.conditions[]?; .type == "Programmed" and .status == "True")' <<<"$gateway" >/dev/null; then
    pass "MaaS Gateway Programmed=True"
  else
    fail "MaaS Gateway is not Programmed=True"
  fi
fi

model=""
if check_exists llminferenceservice "$MODEL_NAME" "$MODEL_NAMESPACE" "Aramock simulator"; then
  model="$(resource_json llminferenceservice "$MODEL_NAME" "$MODEL_NAMESPACE")"
  if jq -e 'any(.status.conditions[]?; .type == "Ready" and .status == "True") or .status.readyReplicas > 0' <<<"$model" >/dev/null; then
    pass "Aramock simulator is Ready"
  else
    warn "Aramock simulator exists but readiness is not yet proven"
  fi
fi

model_ref=""
if check_exists maasmodelref "$MODEL_REF_NAME" "$MODEL_NAMESPACE" "Aramock MaaSModelRef"; then
  model_ref="$(resource_json maasmodelref "$MODEL_REF_NAME" "$MODEL_NAMESPACE")"
  alias="$(jq -r '.status.resolvedModelAlias // empty' <<<"$model_ref")"
  [[ -n "$alias" ]] && pass "MaaSModelRef resolved alias: $alias" || warn "MaaSModelRef has not resolved an alias"
fi

check_exists maasauthpolicy "$AUTH_POLICY_NAME" "$MAAS_NAMESPACE" "Aramock MaaSAuthPolicy" || true
check_exists maassubscription "$SUBSCRIPTION_NAME" "$MAAS_NAMESPACE" "Aramock MaaSSubscription" || true

if [[ -n "${GATEKEEPER_MAAS_URL:-}" ]]; then
  code="$(curl -ksS -o /dev/null -w '%{http_code}' -m 20 \
    "${GATEKEEPER_MAAS_URL%/}/v1/models" || true)"
  if [[ "$code" == "401" || "$code" == "403" || "$code" == "200" ]]; then
    pass "MaaS endpoint responded with expected gateway status HTTP $code"
  else
    fail "MaaS endpoint returned unexpected HTTP $code"
  fi
else
  warn "GATEKEEPER_MAAS_URL is not configured; endpoint smoke test skipped"
fi

printf 'Aramock conformance result: failures=%s warnings=%s\n' "$FAILURES" "$WARNINGS"
if (( FAILURES > 0 )); then
  exit 1
fi
if (( WARNINGS > 0 )); then
  exit 10
fi
