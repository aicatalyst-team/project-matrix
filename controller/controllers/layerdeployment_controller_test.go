package controllers

import (
	"context"
	"testing"

	matrixv1alpha1 "github.com/redhat-ai/project-matrix/controller/api/v1alpha1"
	batchv1 "k8s.io/api/batch/v1"
	apierrors "k8s.io/apimachinery/pkg/api/errors"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/types"
	clientgoscheme "k8s.io/client-go/kubernetes/scheme"
	"sigs.k8s.io/controller-runtime/pkg/client/fake"
	"sigs.k8s.io/controller-runtime/pkg/reconcile"
)

func TestReconcileCreatesGatekeeperJobAndStatusPlan(t *testing.T) {
	scheme := clientgoscheme.Scheme
	if err := matrixv1alpha1.AddToScheme(scheme); err != nil {
		t.Fatal(err)
	}
	deployment := &matrixv1alpha1.LayerDeployment{
		ObjectMeta: metav1.ObjectMeta{Name: "gateway-preview", Namespace: "matrix-system"},
		Spec: matrixv1alpha1.LayerDeploymentSpec{
			Layer:        "Gateway",
			CodeName:     "Gatekeeper",
			Mode:         "Preview",
			DesiredState: "Enabled",
			Profile:      "gateway-evaluation",
		},
	}
	client := fake.NewClientBuilder().WithScheme(scheme).WithObjects(deployment).WithStatusSubresource(deployment).Build()
	reconciler := &LayerDeploymentReconciler{
		Client:                  client,
		GatekeeperExecutorImage: "registry.example/gatekeeper:dev",
	}

	if _, err := reconciler.Reconcile(context.Background(), reconcile.Request{NamespacedName: types.NamespacedName{Name: deployment.Name, Namespace: deployment.Namespace}}); err != nil {
		t.Fatal(err)
	}

	var job batchv1.Job
	if err := client.Get(context.Background(), types.NamespacedName{Name: "project-matrix-gatekeeper-gateway-preview", Namespace: "matrix-system"}, &job); err != nil {
		t.Fatalf("expected Gatekeeper Job: %v", err)
	}
	if job.Spec.Template.Spec.Containers[0].Image != "registry.example/gatekeeper:dev" {
		t.Fatalf("unexpected executor image: %q", job.Spec.Template.Spec.Containers[0].Image)
	}

	var observed matrixv1alpha1.LayerDeployment
	if err := client.Get(context.Background(), types.NamespacedName{Name: deployment.Name, Namespace: deployment.Namespace}, &observed); err != nil {
		t.Fatal(err)
	}
	if observed.Status.Phase != "Installing" {
		t.Fatalf("phase = %q, want Installing", observed.Status.Phase)
	}
	if observed.Status.EvidenceRef != "project-matrix-evidence-gateway-preview" {
		t.Fatalf("unexpected evidence reference: %q", observed.Status.EvidenceRef)
	}
}

func TestReconcileReplacesTerminalGatekeeperJobForRetry(t *testing.T) {
	scheme := clientgoscheme.Scheme
	if err := matrixv1alpha1.AddToScheme(scheme); err != nil {
		t.Fatal(err)
	}
	deployment := &matrixv1alpha1.LayerDeployment{
		ObjectMeta: metav1.ObjectMeta{
			Name:        "gateway-production",
			Namespace:   "matrix-system",
			Annotations: map[string]string{"project-matrix.redhat.com/retry-token": "retry-1"},
		},
		Spec: matrixv1alpha1.LayerDeploymentSpec{
			Layer: "Gateway", CodeName: "Gatekeeper", Mode: "Production", DesiredState: "Enabled", Profile: "gateway-production",
		},
	}
	client := fake.NewClientBuilder().WithScheme(scheme).WithObjects(deployment).WithStatusSubresource(deployment).Build()
	reconciler := &LayerDeploymentReconciler{Client: client, GatekeeperExecutorImage: "registry.example/gatekeeper:dev"}
	request := reconcile.Request{NamespacedName: types.NamespacedName{Name: deployment.Name, Namespace: deployment.Namespace}}

	if _, err := reconciler.Reconcile(context.Background(), request); err != nil {
		t.Fatal(err)
	}
	job := &batchv1.Job{}
	jobKey := types.NamespacedName{Name: "project-matrix-gatekeeper-gateway-production", Namespace: deployment.Namespace}
	if err := client.Get(context.Background(), jobKey, job); err != nil {
		t.Fatal(err)
	}
	job.Status.Failed = 1
	if err := client.Status().Update(context.Background(), job); err != nil {
		t.Fatal(err)
	}
	var latest matrixv1alpha1.LayerDeployment
	if err := client.Get(context.Background(), request.NamespacedName, &latest); err != nil {
		t.Fatal(err)
	}
	latest.Annotations["project-matrix.redhat.com/retry-token"] = "retry-2"
	if err := client.Update(context.Background(), &latest); err != nil {
		t.Fatal(err)
	}

	if _, err := reconciler.Reconcile(context.Background(), request); err != nil {
		t.Fatal(err)
	}
	if err := client.Get(context.Background(), jobKey, &batchv1.Job{}); !apierrors.IsNotFound(err) {
		t.Fatalf("terminal Job should be deleted for retry, got %v", err)
	}
	if _, err := reconciler.Reconcile(context.Background(), request); err != nil {
		t.Fatal(err)
	}
	if err := client.Get(context.Background(), jobKey, &batchv1.Job{}); err != nil {
		t.Fatalf("expected replacement Job: %v", err)
	}
}

func TestReconcileBlocksCompetingActiveLayerOwners(t *testing.T) {
	scheme := clientgoscheme.Scheme
	if err := matrixv1alpha1.AddToScheme(scheme); err != nil {
		t.Fatal(err)
	}
	production := &matrixv1alpha1.LayerDeployment{
		ObjectMeta: metav1.ObjectMeta{Name: "gateway-production", Namespace: "matrix-system"},
		Spec: matrixv1alpha1.LayerDeploymentSpec{
			Layer: "Gateway", CodeName: "Gatekeeper", Mode: "Production", DesiredState: "Enabled", Profile: "gateway-production",
		},
	}
	preview := &matrixv1alpha1.LayerDeployment{
		ObjectMeta: metav1.ObjectMeta{Name: "gateway-preview", Namespace: "matrix-system"},
		Spec: matrixv1alpha1.LayerDeploymentSpec{
			Layer: "Gateway", CodeName: "Gatekeeper", Mode: "Preview", DesiredState: "Enabled", Profile: "gateway-evaluation",
		},
	}
	client := fake.NewClientBuilder().WithScheme(scheme).WithObjects(production, preview).WithStatusSubresource(production, preview).Build()
	reconciler := &LayerDeploymentReconciler{Client: client}

	if _, err := reconciler.Reconcile(context.Background(), reconcile.Request{NamespacedName: types.NamespacedName{Name: preview.Name, Namespace: preview.Namespace}}); err != nil {
		t.Fatal(err)
	}

	var observed matrixv1alpha1.LayerDeployment
	if err := client.Get(context.Background(), types.NamespacedName{Name: preview.Name, Namespace: preview.Namespace}, &observed); err != nil {
		t.Fatal(err)
	}
	if observed.Status.Phase != "Blocked" {
		t.Fatalf("phase = %q, want Blocked", observed.Status.Phase)
	}
}

func TestGatewayStatusExposesComponentGatesAndDemoUseCases(t *testing.T) {
	components := gatewayComponents("Ready")
	if len(components) != 4 {
		t.Fatalf("component count = %d, want 4", len(components))
	}
	if components[0].Name != "MCP Gateway" || components[0].Status != "Healthy" {
		t.Fatalf("MCP component = %#v, want Healthy", components[0])
	}
	if components[1].Name != "MaaS Gateway" || components[1].Status != "Validation gate" {
		t.Fatalf("MaaS component = %#v, want Validation gate", components[1])
	}

	useCases := gatewayDemoUseCases("Ready")
	if len(useCases) != 3 {
		t.Fatalf("demo use-case count = %d, want 3", len(useCases))
	}
	if useCases[0].ActionHref != "/ai-hub/mcp-servers/catalog" {
		t.Fatalf("unexpected MCP demo entry point: %q", useCases[0].ActionHref)
	}
	if useCases[1].Status != "Validation gate" {
		t.Fatalf("MaaS demo status = %q, want Validation gate", useCases[1].Status)
	}
}
