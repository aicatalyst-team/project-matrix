package bff

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	matrixv1alpha1 "github.com/redhat-ai/project-matrix/controller/api/v1alpha1"
	"k8s.io/apimachinery/pkg/types"
	clientgoscheme "k8s.io/client-go/kubernetes/scheme"
	"sigs.k8s.io/controller-runtime/pkg/client"
	"sigs.k8s.io/controller-runtime/pkg/client/fake"
)

func TestServerRequiresDashboardIdentity(t *testing.T) {
	server := newTestServer(t)
	request := httptest.NewRequest(http.MethodGet, RoutePath, nil)
	recorder := httptest.NewRecorder()

	server.ServeHTTP(recorder, request)

	if recorder.Code != http.StatusUnauthorized {
		t.Fatalf("status = %d, want %d", recorder.Code, http.StatusUnauthorized)
	}
}

func TestServerReturnsNullForInitialDeployment(t *testing.T) {
	server := newTestServer(t)
	request := httptest.NewRequest(http.MethodGet, RoutePath+"?namespace=matrix-system", nil)
	request.Header.Set("X-Forwarded-User", "platform-user")
	recorder := httptest.NewRecorder()

	server.ServeHTTP(recorder, request)

	if recorder.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d", recorder.Code, http.StatusOK)
	}
	var envelope map[string]any
	if err := json.Unmarshal(recorder.Body.Bytes(), &envelope); err != nil {
		t.Fatal(err)
	}
	if value, exists := envelope["data"]; !exists || value != nil {
		t.Fatalf("data = %#v, want null", value)
	}
}

func TestServerAcceptsDashboardProxyRewritePath(t *testing.T) {
	server := newTestServer(t)
	request := httptest.NewRequest(http.MethodGet, ProxyRoutePath+"?namespace=matrix-system", nil)
	request.Header.Set("X-Forwarded-User", "platform-user")
	recorder := httptest.NewRecorder()

	server.ServeHTTP(recorder, request)

	if recorder.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d: %s", recorder.Code, http.StatusOK, recorder.Body.String())
	}
}

func TestServerAppliesOnlyFixedGatekeeperIntent(t *testing.T) {
	server := newTestServer(t)

	production := validRequest("Production", "gateway-production")
	created := callApply(t, server, production)
	if created.Code != http.StatusCreated {
		t.Fatalf("create status = %d, want %d: %s", created.Code, http.StatusCreated, created.Body.String())
	}

	var deployment matrixv1alpha1.LayerDeployment
	if err := server.Client.Get(t.Context(), types.NamespacedName{Name: "gatekeeper", Namespace: "matrix-system"}, &deployment); err != nil {
		t.Fatal(err)
	}
	if deployment.Spec.Mode != "Production" || deployment.Spec.Profile != "gateway-production" {
		t.Fatalf("unexpected created spec: %#v", deployment.Spec)
	}

	preview := validRequest("Preview", "gateway-evaluation")
	updated := callApply(t, server, preview)
	if updated.Code != http.StatusOK {
		t.Fatalf("update status = %d, want %d: %s", updated.Code, http.StatusOK, updated.Body.String())
	}
	if err := server.Client.Get(t.Context(), client.ObjectKey{Name: "gatekeeper", Namespace: "matrix-system"}, &deployment); err != nil {
		t.Fatal(err)
	}
	if deployment.Spec.Mode != "Preview" || deployment.Spec.Profile != "gateway-evaluation" {
		t.Fatalf("unexpected updated spec: %#v", deployment.Spec)
	}
}

func TestServerRejectsCustomerProfileAndNamespaceMutation(t *testing.T) {
	server := newTestServer(t)

	unknownField := []byte(`{"namespace":"matrix-system","spec":{"layer":"Gateway","codeName":"Gatekeeper","mode":"Preview","desiredState":"Enabled","profile":"gateway-evaluation","customerProfile":"saudi-aramco-gateway-evaluation","coexistence":{"enabled":true,"retainInactiveLane":true}}}`)
	recorder := callJSON(t, server, unknownField)
	if recorder.Code != http.StatusBadRequest {
		t.Fatalf("unknown field status = %d, want %d", recorder.Code, http.StatusBadRequest)
	}

	wrongNamespace := validRequest("Preview", "gateway-evaluation")
	wrongNamespace = bytes.Replace(wrongNamespace, []byte(`"matrix-system"`), []byte(`"customer-workload"`), 1)
	recorder = callJSON(t, server, wrongNamespace)
	if recorder.Code != http.StatusBadRequest {
		t.Fatalf("namespace status = %d, want %d", recorder.Code, http.StatusBadRequest)
	}
}

func newTestServer(t *testing.T) *Server {
	t.Helper()
	scheme := clientgoscheme.Scheme
	if err := matrixv1alpha1.AddToScheme(scheme); err != nil {
		t.Fatal(err)
	}
	kubeClient := fake.NewClientBuilder().WithScheme(scheme).Build()
	return NewServer(kubeClient, "matrix-system", "gatekeeper", "X-Forwarded-User")
}

func validRequest(mode, profile string) []byte {
	return []byte(`{"namespace":"matrix-system","spec":{"layer":"Gateway","codeName":"Gatekeeper","mode":"` + mode + `","desiredState":"Enabled","profile":"` + profile + `","coexistence":{"enabled":true,"retainInactiveLane":true}}}`)
}

func callApply(t *testing.T, server *Server, body []byte) *httptest.ResponseRecorder {
	t.Helper()
	return callJSON(t, server, body)
}

func callJSON(t *testing.T, server *Server, body []byte) *httptest.ResponseRecorder {
	t.Helper()
	request := httptest.NewRequest(http.MethodPost, RoutePath, bytes.NewReader(body))
	request.Header.Set("X-Forwarded-User", "platform-user")
	recorder := httptest.NewRecorder()
	server.ServeHTTP(recorder, request)
	return recorder
}
