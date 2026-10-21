package dependency

import (
	"fmt"

	matrixv1alpha1 "github.com/redhat-ai/project-matrix/controller/api/v1alpha1"
)

type Intent struct {
	Namespace    string
	Name         string
	Layer        string
	CodeName     string
	Mode         string
	Profile      string
	DesiredState string
}

type Claim struct {
	Key       string
	Value     string
	Owner     string
	Shareable bool
}

type Conflict struct {
	Key       string
	Existing  string
	Requested string
	Message   string
	Owners    []string
}

func IntentFromDeployment(deployment matrixv1alpha1.LayerDeployment) Intent {
	return Intent{
		Namespace:    deployment.Namespace,
		Name:         deployment.Name,
		Layer:        deployment.Spec.Layer,
		CodeName:     deployment.Spec.CodeName,
		Mode:         deployment.Spec.Mode,
		Profile:      deployment.Spec.Profile,
		DesiredState: deployment.Spec.DesiredState,
	}
}

func Resolve(intents []Intent) []Conflict {
	claims := map[string]Claim{}
	conflicts := make([]Conflict, 0)
	for _, intent := range intents {
		if intent.DesiredState != "Enabled" {
			continue
		}
		owner := intent.Namespace + "/" + intent.Name
		for _, requested := range claimsFor(intent, owner) {
			existing, found := claims[requested.Key]
			if !found {
				claims[requested.Key] = requested
				continue
			}
			if requested.Shareable && existing.Shareable && requested.Value == existing.Value {
				continue
			}
			if existing.Owner == requested.Owner && existing.Value == requested.Value {
				continue
			}
			conflicts = append(conflicts, Conflict{
				Key:       requested.Key,
				Existing:  existing.Value,
				Requested: requested.Value,
				Message: fmt.Sprintf(
					"dependency %q is already claimed by %s (%s); requested by %s (%s)",
					requested.Key, existing.Owner, existing.Value, requested.Owner, requested.Value,
				),
				Owners: []string{existing.Owner, requested.Owner},
			})
		}
	}
	return conflicts
}

func Involves(conflict Conflict, namespace, name string) bool {
	owner := namespace + "/" + name
	for _, candidate := range conflict.Owners {
		if candidate == owner {
			return true
		}
	}
	return false
}

func claimsFor(intent Intent, owner string) []Claim {
	profile := intent.Profile
	if profile == "" {
		profile = intent.Mode
	}
	claims := []Claim{
		{
			Key:       "layer/" + intent.Layer + "/active-owner",
			Value:     owner,
			Owner:     owner,
			Shareable: false,
		},
		{
			Key:       "platform/gateway-api/data-science-gateway-class",
			Value:     "shared",
			Owner:     owner,
			Shareable: true,
		},
	}
	if intent.Layer == "Gateway" {
		claims = append(claims,
			Claim{
				Key:       "gateway/active-mcp-route",
				Value:     profile,
				Owner:     owner,
				Shareable: false,
			},
			Claim{
				Key:       "gateway/identity-contract",
				Value:     "oidc",
				Owner:     owner,
				Shareable: true,
			},
		)
	}
	return claims
}
