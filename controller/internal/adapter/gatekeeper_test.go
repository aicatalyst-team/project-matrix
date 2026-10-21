package adapter

import (
	"testing"

	matrixv1alpha1 "github.com/redhat-ai/project-matrix/controller/api/v1alpha1"
)

func TestGatekeeperJobUsesSelectedProfileAndNoCredentials(t *testing.T) {
	deployment := &matrixv1alpha1.LayerDeployment{}
	deployment.Name = "gateway-preview"
	deployment.Namespace = "matrix-system"
	deployment.Spec = matrixv1alpha1.LayerDeploymentSpec{
		Layer:        "Gateway",
		CodeName:     "Gatekeeper",
		Mode:         "Preview",
		DesiredState: "Enabled",
		Profile:      "gateway-evaluation",
	}

	job := GatekeeperJob(deployment, "registry.example/gatekeeper:dev")
	if job.Spec.Template.Spec.Containers[0].Image != "registry.example/gatekeeper:dev" {
		t.Fatalf("unexpected image: %q", job.Spec.Template.Spec.Containers[0].Image)
	}
	args := job.Spec.Template.Spec.Containers[0].Args
	if len(args) != 1 || args[0] != "preview-install" {
		t.Fatalf("unexpected args: %#v", args)
	}
	previewEnv := map[string]string{}
	for _, env := range job.Spec.Template.Spec.Containers[0].Env {
		if env.Value != "" {
			previewEnv[env.Name] = env.Value
		}
	}
	if previewEnv["GATEKEEPER_GATEWAY_NAMESPACE"] != "mcp-gateway-preview" ||
		previewEnv["GATEKEEPER_GATEWAY_NAME"] != "mcp-gateway-preview" ||
		previewEnv["GATEKEEPER_PREVIEW_SOURCE"] != "upstream" {
		t.Fatalf("preview job is not isolated: %#v", previewEnv)
	}
	for _, env := range job.Spec.Template.Spec.Containers[0].Env {
		if env.Name == "GATEKEEPER_BEARER_TOKEN" || env.Name == "OIDC_CLIENT_SECRET" {
			t.Fatal("job must not embed customer credentials")
		}
	}
	evidenceEnv := false
	for _, env := range job.Spec.Template.Spec.Containers[0].Env {
		if env.Name == "PROJECT_MATRIX_EVIDENCE_CONFIGMAP" {
			evidenceEnv = true
		}
	}
	if !evidenceEnv {
		t.Fatalf("evidence handoff is missing: %#v", job.Spec.Template.Spec.Containers[0].Env)
	}
	if job.Spec.Template.Spec.ServiceAccountName != "project-matrix-gatekeeper-runner" {
		t.Fatalf("unexpected service account: %q", job.Spec.Template.Spec.ServiceAccountName)
	}
}
