package plan

import (
	"testing"

	matrixv1alpha1 "github.com/redhat-ai/project-matrix/controller/api/v1alpha1"
)

func TestPreviewGatekeeperDefaultsToEvaluationProfile(t *testing.T) {
	result := Build(matrixv1alpha1.LayerDeploymentSpec{
		Layer:        "Gateway",
		CodeName:     "Gatekeeper",
		Mode:         Preview,
		DesiredState: Enabled,
	})

	if result.SelectedProfile != "gateway-evaluation" {
		t.Fatalf("selected profile = %q, want gateway-evaluation", result.SelectedProfile)
	}
	if result.ActiveMode != Preview {
		t.Fatalf("active mode = %q, want Preview", result.ActiveMode)
	}
	if result.Phase != "Preflighting" {
		t.Fatalf("phase = %q, want Preflighting", result.Phase)
	}
}

func TestProductionGatekeeperDefaultsToProductionProfile(t *testing.T) {
	result := Build(matrixv1alpha1.LayerDeploymentSpec{
		Layer:        "Gateway",
		CodeName:     "Gatekeeper",
		Mode:         Production,
		DesiredState: Enabled,
	})

	if result.SelectedProfile != "gateway-production" {
		t.Fatalf("selected profile = %q, want gateway-production", result.SelectedProfile)
	}
	if result.SupportBoundary == "" || result.SupportBoundary[:10] != "Production" {
		t.Fatalf("unexpected support boundary: %q", result.SupportBoundary)
	}
}

func TestInvalidLayerStopsBeforeMutation(t *testing.T) {
	result := Build(matrixv1alpha1.LayerDeploymentSpec{
		Layer:        "Gateway",
		CodeName:     "WrongName",
		Mode:         Preview,
		DesiredState: Enabled,
	})

	if result.Phase != "Blocked" {
		t.Fatalf("phase = %q, want Blocked", result.Phase)
	}
	if result.Execution != "blocked-before-mutation" {
		t.Fatalf("execution = %q, want blocked-before-mutation", result.Execution)
	}
}

func TestDisabledLayerDoesNotPlanInstallation(t *testing.T) {
	result := Build(matrixv1alpha1.LayerDeploymentSpec{
		Layer:        "Gateway",
		CodeName:     "Gatekeeper",
		Mode:         Preview,
		DesiredState: Disabled,
	})

	if result.Phase != "Disabled" || result.Execution != "disabled-by-user" {
		t.Fatalf("unexpected disabled result: phase=%q execution=%q", result.Phase, result.Execution)
	}
}
