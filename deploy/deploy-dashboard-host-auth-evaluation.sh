#!/usr/bin/env bash
set -euo pipefail

# Add the isolated Red Hat kube-auth-proxy front door for the combined
# Dashboard host evaluation. This does not modify managed GatewayConfig,
# production OAuthClient, or production Dashboard resources.

command -v oc >/dev/null || { echo "oc is required" >&2; exit 1; }
command -v openssl >/dev/null || { echo "openssl is required" >&2; exit 1; }

PLATFORM_NAMESPACE="${PLATFORM_NAMESPACE:-redhat-ods-applications}"
AUTH_NAMESPACE="${AUTH_NAMESPACE:-openshift-ingress}"
EVAL_DEPLOYMENT="${EVAL_DEPLOYMENT:-project-matrix-dashboard-eval}"
AUTH_NAME="${AUTH_NAME:-project-matrix-dashboard-eval-auth}"
AUTH_HOST="${AUTH_HOST:-project-matrix-dashboard-eval.apps.ocp-gb.ibm.redhataicatalyst.com}"
AUTH_CLIENT="${AUTH_CLIENT:-project-matrix-dashboard-eval}"
AUTH_IMAGE="${PROJECT_MATRIX_KUBE_AUTH_PROXY_IMAGE:-registry.redhat.io/rhoai/odh-kube-auth-proxy-rhel9@sha256:9b3c12230ba31b9c1962467ed46c1aa2eec8984bfe1ffc1fdb2225f6f4a6e325}"
OAUTH_AUTHORIZE_URL="${OAUTH_AUTHORIZE_URL:-https://oauth-openshift.${AUTH_HOST#*.}/oauth/authorize}"

oc get deployment/"${EVAL_DEPLOYMENT}" -n "${PLATFORM_NAMESPACE}" >/dev/null
oc get serviceaccount/kube-auth-proxy -n "${AUTH_NAMESPACE}" >/dev/null

if ! oc get oauthclient/"${AUTH_CLIENT}" >/dev/null 2>&1; then
  client_secret="$(openssl rand -hex 32)"
  oc apply -f - <<YAML
apiVersion: oauth.openshift.io/v1
kind: OAuthClient
metadata:
  name: ${AUTH_CLIENT}
  labels:
    project-matrix.redhat.com/component: dashboard-host-evaluation-auth
    project-matrix.redhat.com/managed: "true"
grantMethod: auto
redirectURIs:
- https://${AUTH_HOST}/oauth2/callback
secret: ${client_secret}
YAML
fi

redirect_uri="$(oc get oauthclient/"${AUTH_CLIENT}" -o jsonpath='{.redirectURIs[0]}')"
test "${redirect_uri}" = "https://${AUTH_HOST}/oauth2/callback" || {
  echo "OAuthClient redirect URI does not match ${AUTH_HOST}" >&2
  exit 1
}

if ! oc get secret/${AUTH_NAME}-creds -n "${AUTH_NAMESPACE}" >/dev/null 2>&1; then
  client_secret="$(oc get oauthclient/"${AUTH_CLIENT}" -o jsonpath='{.secret}')"
  cookie_secret="$(openssl rand -hex 16)"
  oc apply -f - <<YAML
apiVersion: v1
kind: Secret
metadata:
  name: ${AUTH_NAME}-creds
  namespace: ${AUTH_NAMESPACE}
  labels:
    project-matrix.redhat.com/component: dashboard-host-evaluation-auth
    project-matrix.redhat.com/managed: "true"
type: Opaque
stringData:
  OAUTH2_PROXY_CLIENT_ID: ${AUTH_CLIENT}
  OAUTH2_PROXY_CLIENT_SECRET: ${client_secret}
  OAUTH2_PROXY_COOKIE_SECRET: ${cookie_secret}
YAML
fi

oc apply -f - <<YAML
apiVersion: v1
kind: Service
metadata:
  name: ${AUTH_NAME}-upstream
  namespace: ${PLATFORM_NAMESPACE}
  labels:
    app: ${AUTH_NAME}-upstream
    project-matrix.redhat.com/component: dashboard-host-evaluation
    project-matrix.redhat.com/managed: "true"
spec:
  selector:
    app: ${EVAL_DEPLOYMENT}
    deployment: ${EVAL_DEPLOYMENT}
  ports:
  - name: host-http
    port: 8080
    protocol: TCP
    targetPort: 8080
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: ${AUTH_NAME}-upstream
  namespace: ${PLATFORM_NAMESPACE}
  labels:
    project-matrix.redhat.com/component: dashboard-host-evaluation
    project-matrix.redhat.com/managed: "true"
spec:
  podSelector:
    matchLabels:
      app: ${EVAL_DEPLOYMENT}
      deployment: ${EVAL_DEPLOYMENT}
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: ${AUTH_NAMESPACE}
      podSelector:
        matchLabels:
          app: ${AUTH_NAME}
    ports:
    - protocol: TCP
      port: 8080
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: ${AUTH_NAMESPACE}
    ports:
    - protocol: TCP
      port: 8443
YAML

oc apply -f - <<YAML
apiVersion: v1
kind: Service
metadata:
  name: ${AUTH_NAME}
  namespace: ${AUTH_NAMESPACE}
  labels:
    app: ${AUTH_NAME}
    project-matrix.redhat.com/component: dashboard-host-evaluation-auth
    project-matrix.redhat.com/managed: "true"
  annotations:
    service.beta.openshift.io/serving-cert-secret-name: ${AUTH_NAME}-tls
spec:
  selector:
    app: ${AUTH_NAME}
  ports:
  - name: https
    port: 8443
    protocol: TCP
    targetPort: https
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${AUTH_NAME}
  namespace: ${AUTH_NAMESPACE}
  labels:
    app: ${AUTH_NAME}
    project-matrix.redhat.com/component: dashboard-host-evaluation-auth
    project-matrix.redhat.com/managed: "true"
spec:
  replicas: 2
  selector:
    matchLabels:
      app: ${AUTH_NAME}
  template:
    metadata:
      labels:
        app: ${AUTH_NAME}
        project-matrix.redhat.com/component: dashboard-host-evaluation-auth
    spec:
      serviceAccountName: kube-auth-proxy
      containers:
      - name: kube-auth-proxy
        image: ${AUTH_IMAGE}
        imagePullPolicy: IfNotPresent
        args:
        - --http-address=0.0.0.0:4180
        - --https-address=0.0.0.0:8443
        - --metrics-address=0.0.0.0:9000
        - --email-domain=*
        - --upstream=http://${AUTH_NAME}-upstream.${PLATFORM_NAMESPACE}.svc.cluster.local:8080
        - --skip-provider-button
        - --skip-jwt-bearer-tokens=true
        - --pass-access-token=true
        - --set-xauthrequest=true
        - --enable-k8s-token-validation=true
        - --login-url=${OAUTH_AUTHORIZE_URL}
        - --redirect-url=https://${AUTH_HOST}/oauth2/callback
        - --redeem-url=https://oauth-openshift.openshift-authentication.svc:443/oauth/token
        - --provider-ca-file=/etc/pki/tls/certs/openshift-service-ca.crt
        - --tls-cert-file=/etc/tls/private/tls.crt
        - --tls-key-file=/etc/tls/private/tls.key
        - --tls-min-version=TLS1.2
        - --use-system-trust-store=true
        - --cookie-expire=24h0m0s
        - --cookie-refresh=1h0m0s
        - --cookie-secure=true
        - --cookie-httponly=true
        - --cookie-samesite=lax
        - --cookie-name=_project_matrix_dashboard_eval
        - --provider=openshift
        - --ssl-insecure-skip-verify=false
        - --scope=user:full
        env:
        - name: OAUTH2_PROXY_CLIENT_ID
          valueFrom:
            secretKeyRef:
              name: ${AUTH_NAME}-creds
              key: OAUTH2_PROXY_CLIENT_ID
        - name: OAUTH2_PROXY_CLIENT_SECRET
          valueFrom:
            secretKeyRef:
              name: ${AUTH_NAME}-creds
              key: OAUTH2_PROXY_CLIENT_SECRET
        - name: OAUTH2_PROXY_COOKIE_SECRET
          valueFrom:
            secretKeyRef:
              name: ${AUTH_NAME}-creds
              key: OAUTH2_PROXY_COOKIE_SECRET
        ports:
        - name: https
          containerPort: 8443
          protocol: TCP
        - name: http
          containerPort: 4180
          protocol: TCP
        - name: metrics
          containerPort: 9000
          protocol: TCP
        resources:
          requests:
            cpu: 100m
            memory: 64Mi
          limits:
            memory: 128Mi
        securityContext:
          allowPrivilegeEscalation: false
          capabilities:
            drop: [ALL]
          readOnlyRootFilesystem: true
        volumeMounts:
        - name: tls-certs
          mountPath: /etc/tls/private
          readOnly: true
        - name: service-ca
          mountPath: /etc/pki/tls/certs/openshift-service-ca.crt
          subPath: service-ca.crt
          readOnly: true
      volumes:
      - name: tls-certs
        secret:
          secretName: ${AUTH_NAME}-tls
      - name: service-ca
        configMap:
          name: openshift-service-ca.crt
          items:
          - key: service-ca.crt
            path: service-ca.crt
      securityContext:
        runAsNonRoot: true
        seccompProfile:
          type: RuntimeDefault
YAML

if ! oc get route/"${AUTH_NAME}" -n "${AUTH_NAMESPACE}" >/dev/null 2>&1; then
  oc create -f - <<YAML
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: ${AUTH_NAME}
  namespace: ${AUTH_NAMESPACE}
  annotations:
    router.openshift.io/service-ca-certificate: "true"
  labels:
    app: ${AUTH_NAME}
    project-matrix.redhat.com/component: dashboard-host-evaluation-auth
    project-matrix.redhat.com/managed: "true"
spec:
  host: ${AUTH_HOST}
  to:
    kind: Service
    name: ${AUTH_NAME}
  port:
    targetPort: https
  tls:
    termination: reencrypt
    insecureEdgeTerminationPolicy: Redirect
YAML
fi

oc rollout status deployment/"${AUTH_NAME}" -n "${AUTH_NAMESPACE}" --timeout=180s
oc get route/"${AUTH_NAME}" -n "${AUTH_NAMESPACE}" \
  -o jsonpath='https://{.spec.host}{"\n"}'
