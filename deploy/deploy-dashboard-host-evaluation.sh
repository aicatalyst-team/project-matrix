#!/usr/bin/env bash
set -euo pipefail

# Deploy the combined Project Matrix/OpenShift AI Dashboard host as an isolated
# evaluation copy. This does not replace the operator-managed Dashboard.

command -v oc >/dev/null || { echo "oc is required" >&2; exit 1; }
command -v jq >/dev/null || { echo "jq is required" >&2; exit 1; }

PLATFORM_NAMESPACE="${PLATFORM_NAMESPACE:-redhat-ods-applications}"
BUILD_NAMESPACE="${BUILD_NAMESPACE:-project-matrix-build}"
SOURCE_DEPLOYMENT="${SOURCE_DEPLOYMENT:-rhods-dashboard}"
EVAL_DEPLOYMENT="${EVAL_DEPLOYMENT:-project-matrix-dashboard-eval}"
EVAL_SERVICE="${EVAL_SERVICE:-project-matrix-dashboard-eval}"
EVAL_ROUTE="${EVAL_ROUTE:-project-matrix-dashboard-eval}"
IMAGE="${PROJECT_MATRIX_DASHBOARD_HOST_IMAGE:-image-registry.openshift-image-registry.svc:5000/project-matrix-build/project-matrix-dashboard-host@sha256:6b8060a28237430a8b3a88e39ef9e3ed1e7791f8a83dd873b10519d2df8ee79a}"

oc get deployment/"${SOURCE_DEPLOYMENT}" -n "${PLATFORM_NAMESPACE}" >/dev/null

# Permit only this existing Dashboard identity to pull the internal evaluation
# image. No registry credential is copied into the platform namespace.
oc create rolebinding project-matrix-dashboard-image-puller \
  --clusterrole=system:image-puller \
  --serviceaccount="${PLATFORM_NAMESPACE}:rhods-dashboard" \
  -n "${BUILD_NAMESPACE}" \
  --dry-run=client -o yaml | oc apply -f - >/dev/null

oc get deployment/"${SOURCE_DEPLOYMENT}" -n "${PLATFORM_NAMESPACE}" -o json |
  jq --arg name "${EVAL_DEPLOYMENT}" --arg image "${IMAGE}" '
    del(.metadata.managedFields,.metadata.resourceVersion,.metadata.uid,
        .metadata.creationTimestamp,.metadata.generation,.metadata.ownerReferences,
        .status)
    | .metadata.name=$name
    | .metadata.labels={"app":$name,"app.kubernetes.io/part-of":"project-matrix-dashboard",
        "project-matrix.redhat.com/component":"dashboard-host-evaluation",
        "project-matrix.redhat.com/managed":"true"}
    | .spec.replicas=1
    | .spec.selector.matchLabels={"app":$name,"deployment":$name}
    | .spec.template.metadata.labels={"app":$name,"deployment":$name,
        "app.kubernetes.io/part-of":"project-matrix-dashboard",
        "project-matrix.redhat.com/component":"dashboard-host-evaluation"}
    | .spec.template.metadata.annotations=((.spec.template.metadata.annotations // {}) +
        {"project-matrix.redhat.com/lane":"evaluation"})
    | .spec.template.spec.containers |= map(
        if .name=="rhods-dashboard" then .image=$image | .imagePullPolicy="IfNotPresent"
        else . end)
  ' | oc apply -f -

oc apply -f - <<YAML
apiVersion: v1
kind: Service
metadata:
  name: ${EVAL_SERVICE}
  namespace: ${PLATFORM_NAMESPACE}
  labels:
    app: ${EVAL_DEPLOYMENT}
    project-matrix.redhat.com/component: dashboard-host-evaluation
    project-matrix.redhat.com/managed: "true"
  annotations:
    service.beta.kubernetes.io/backend-protocol: HTTPS
spec:
  selector:
    app: ${EVAL_DEPLOYMENT}
    deployment: ${EVAL_DEPLOYMENT}
  ports:
  - name: dashboard-ui
    port: 8443
    protocol: TCP
    targetPort: dashboard-ui
YAML

if ! oc get route/"${EVAL_ROUTE}" -n "${PLATFORM_NAMESPACE}" >/dev/null 2>&1; then
oc create -f - <<YAML
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: ${EVAL_ROUTE}
  namespace: ${PLATFORM_NAMESPACE}
  labels:
    app: ${EVAL_DEPLOYMENT}
    project-matrix.redhat.com/component: dashboard-host-evaluation
    project-matrix.redhat.com/managed: "true"
spec:
  to:
    kind: Service
    name: ${EVAL_SERVICE}
  port:
    targetPort: dashboard-ui
  tls:
    termination: edge
    insecureEdgeTerminationPolicy: Redirect
YAML
fi

service_ca="$(oc get configmap/openshift-service-ca.crt -n "${PLATFORM_NAMESPACE}" -o jsonpath='{.data.service-ca\.crt}')"
oc get route/"${EVAL_ROUTE}" -n "${PLATFORM_NAMESPACE}" -o json |
  jq --arg ca "${service_ca}" 'del(.status) | .spec.tls={"termination":"reencrypt",
    "insecureEdgeTerminationPolicy":"Redirect","destinationCACertificate":$ca}' |
  oc replace -f -

oc rollout status deployment/"${EVAL_DEPLOYMENT}" -n "${PLATFORM_NAMESPACE}" --timeout=180s
oc get route/"${EVAL_ROUTE}" -n "${PLATFORM_NAMESPACE}" \
  -o jsonpath='https://{.spec.host}{"\n"}'
