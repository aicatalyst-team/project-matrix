package plan

import (
	"fmt"
	"strings"

	matrixv1alpha1 "github.com/redhat-ai/project-matrix/controller/api/v1alpha1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

const (
	Production = "Production"
	Preview    = "Preview"
	Enabled    = "Enabled"
	Disabled   = "Disabled"

	ConditionAccepted             = "Accepted"
	ConditionDependenciesResolved = "DependenciesResolved"
	ConditionAdapterReady         = "AdapterReady"
	ConditionReady                = "Ready"
)

type Plan struct {
	Layer           string             `json:"layer"`
	CodeName        string             `json:"codeName"`
	Mode            string             `json:"mode"`
	SelectedProfile string             `json:"selectedProfile"`
	Phase           string             `json:"phase"`
	ActiveMode      string             `json:"activeMode"`
	SupportBoundary string             `json:"supportBoundary"`
	Execution       string             `json:"execution"`
	Conditions      []metav1.Condition `json:"conditions"`
	Message         string             `json:"message"`
}

var layerCodeNames = map[string]string{
	"Infrastructure":          "Bedrock",
	"vLLM (Core)":             "Ember",
	"llm-d":                   "Flux",
	"OGX":                     "Bridge",
	"Gateway":                 "Gatekeeper",
	"Secure Agent Onboarding": "Bastion",
	"AgentOps":                "Lens",
	"BYOA":                    "Loom",
}

func Build(spec matrixv1alpha1.LayerDeploymentSpec) Plan {
	selectedProfile := spec.Profile
	if selectedProfile == "" {
		selectedProfile = defaultProfile(spec.Layer, spec.Mode)
	}

	result := Plan{
		Layer:           spec.Layer,
		CodeName:        spec.CodeName,
		Mode:            spec.Mode,
		SelectedProfile: selectedProfile,
		Phase:           "Pending",
		ActiveMode:      "Unknown",
		SupportBoundary: supportBoundary(spec.Mode),
		Execution:       "not-started",
	}

	if spec.DesiredState == Disabled {
		result.Phase = "Disabled"
		result.Execution = "disabled-by-user"
		result.Message = "LayerDeployment is disabled by the end-user operating-mode contract."
		result.Conditions = []metav1.Condition{
			condition(ConditionAccepted, metav1.ConditionTrue, "Disabled", result.Message),
			condition(ConditionReady, metav1.ConditionFalse, "Disabled", result.Message),
		}
		return result
	}

	if spec.DesiredState != Enabled {
		return blocked(result, "InvalidDesiredState", fmt.Sprintf("desiredState %q must be Enabled or Disabled", spec.DesiredState))
	}
	if spec.Mode != Production && spec.Mode != Preview {
		return blocked(result, "InvalidMode", fmt.Sprintf("mode %q must be Production or Preview", spec.Mode))
	}
	expectedCodeName, knownLayer := layerCodeNames[spec.Layer]
	if !knownLayer {
		return blocked(result, "UnknownLayer", fmt.Sprintf("layer %q is not in the canonical Red Hat AI: Agentic Strategy stack", spec.Layer))
	}
	if spec.CodeName != expectedCodeName {
		return blocked(result, "InvalidLayerIdentity", fmt.Sprintf("layer %q must use codeName %q, got %q", spec.Layer, expectedCodeName, spec.CodeName))
	}
	if strings.TrimSpace(spec.Profile) != "" && !validProfile(spec.Layer, spec.Mode, spec.Profile) {
		return blocked(result, "InvalidProfile", fmt.Sprintf("profile %q is not valid for %s in %s mode", spec.Profile, spec.Layer, spec.Mode))
	}

	result.ActiveMode = spec.Mode
	result.Phase = "Preflighting"
	result.Execution = "plan-only"
	result.Conditions = []metav1.Condition{
		condition(ConditionAccepted, metav1.ConditionTrue, "Accepted", "Layer identity and operating mode are valid."),
		condition(ConditionDependenciesResolved, metav1.ConditionTrue, "StaticDependenciesResolved", "The cross-layer planner accepted the declared layer contract; live cluster preflight remains required."),
		condition(ConditionAdapterReady, metav1.ConditionFalse, "AdapterNotImplemented", adapterMessage(spec.Layer)),
		condition(ConditionReady, metav1.ConditionFalse, "AwaitingAdapter", "The deployment plan is recorded, but no layer adapter has executed it."),
	}
	result.Message = "Plan accepted; execution is intentionally blocked until the layer adapter is installed."
	return result
}

func adapterMessage(layer string) string {
	if layer == "Gateway" {
		return "Gatekeeper is the Gateway horizontal adapter; the same shipped control plane selects the Red Hat-supported Production lane or the isolated upstream Innovation lane."
	}
	return fmt.Sprintf("No Project Matrix adapter is implemented yet for the %s layer.", layer)
}

func defaultProfile(layer, mode string) string {
	if layer == "Gateway" && mode == Preview {
		return "gateway-evaluation"
	}
	if layer == "Gateway" && mode == Production {
		return "gateway-production"
	}
	return "unassigned"
}

func validProfile(layer, mode, profile string) bool {
	if layer != "Gateway" {
		return false
	}
	return (mode == Preview && profile == "gateway-evaluation") ||
		(mode == Production && profile == "gateway-production")
}

func supportBoundary(mode string) string {
	if mode == Preview {
		return "Innovation lane: Technology Preview/Developer Preview and other explicitly disclosed non-production capabilities."
	}
	if mode == Production {
		return "Production lane: only the target release's Red Hat-supported configuration may be claimed."
	}
	return "Unknown until the operating mode is valid."
}

func blocked(result Plan, reason, message string) Plan {
	result.Phase = "Blocked"
	result.Execution = "blocked-before-mutation"
	result.Message = message
	result.Conditions = []metav1.Condition{
		condition(ConditionAccepted, metav1.ConditionFalse, reason, message),
		condition(ConditionDependenciesResolved, metav1.ConditionFalse, reason, message),
		condition(ConditionReady, metav1.ConditionFalse, reason, "No cluster mutation was attempted."),
	}
	return result
}

// Block exposes the same fail-before-mutation result for live dependency
// resolvers that run after the static LayerDeployment validation.
func Block(result Plan, reason, message string) Plan {
	return blocked(result, reason, message)
}

func condition(conditionType string, status metav1.ConditionStatus, reason, message string) metav1.Condition {
	return metav1.Condition{
		Type:    conditionType,
		Status:  status,
		Reason:  reason,
		Message: message,
	}
}
