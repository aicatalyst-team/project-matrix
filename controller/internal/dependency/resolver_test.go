package dependency

import "testing"

func TestProductionAndPreviewModesOnOneIntentDoNotConflict(t *testing.T) {
	conflicts := Resolve([]Intent{{
		Namespace:    "matrix-system",
		Name:         "gateway",
		Layer:        "Gateway",
		CodeName:     "Gatekeeper",
		Mode:         "Preview",
		Profile:      "gateway-evaluation",
		DesiredState: "Enabled",
	}})
	if len(conflicts) != 0 {
		t.Fatalf("single mode-switch intent produced conflicts: %#v", conflicts)
	}
}

func TestTwoOwnersOfOneActiveLayerAreBlocked(t *testing.T) {
	conflicts := Resolve([]Intent{
		{Namespace: "matrix-system", Name: "gateway-production", Layer: "Gateway", CodeName: "Gatekeeper", Mode: "Production", Profile: "gateway-production", DesiredState: "Enabled"},
		{Namespace: "matrix-system", Name: "gateway-preview", Layer: "Gateway", CodeName: "Gatekeeper", Mode: "Preview", Profile: "gateway-evaluation", DesiredState: "Enabled"},
	})
	if len(conflicts) == 0 {
		t.Fatal("expected active-owner conflict")
	}
	if !Involves(conflicts[0], "matrix-system", "gateway-preview") {
		t.Fatalf("conflict does not identify requested owner: %#v", conflicts[0])
	}
}

func TestDisabledIntentDoesNotClaimDependencies(t *testing.T) {
	conflicts := Resolve([]Intent{
		{Namespace: "matrix-system", Name: "disabled", Layer: "Gateway", CodeName: "Gatekeeper", Mode: "Preview", DesiredState: "Disabled"},
		{Namespace: "matrix-system", Name: "enabled", Layer: "Gateway", CodeName: "Gatekeeper", Mode: "Production", DesiredState: "Enabled"},
	})
	if len(conflicts) != 0 {
		t.Fatalf("disabled intent produced conflicts: %#v", conflicts)
	}
}
