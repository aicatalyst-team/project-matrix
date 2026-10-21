package v1alpha1

import (
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"
)

type LayerDeploymentSpec struct {
	Layer           string          `json:"layer"`
	CodeName        string          `json:"codeName"`
	Mode            string          `json:"mode"`
	DesiredState    string          `json:"desiredState"`
	Profile         string          `json:"profile,omitempty"`
	Coexistence     CoexistenceSpec `json:"coexistence,omitempty"`
	CustomerProfile string          `json:"customerProfile,omitempty"`
}

type CoexistenceSpec struct {
	Enabled            *bool `json:"enabled,omitempty"`
	RetainInactiveLane *bool `json:"retainInactiveLane,omitempty"`
}

type LayerDeploymentStatus struct {
	Phase           string             `json:"phase,omitempty"`
	ActiveMode      string             `json:"activeMode,omitempty"`
	Conditions      []metav1.Condition `json:"conditions,omitempty"`
	EvidenceRef     string             `json:"evidenceRef,omitempty"`
	SupportBoundary string             `json:"supportBoundary,omitempty"`
}

type LayerDeployment struct {
	metav1.TypeMeta   `json:",inline"`
	metav1.ObjectMeta `json:"metadata,omitempty"`
	Spec              LayerDeploymentSpec   `json:"spec,omitempty"`
	Status            LayerDeploymentStatus `json:"status,omitempty"`
}

type LayerDeploymentList struct {
	metav1.TypeMeta `json:",inline"`
	metav1.ListMeta `json:"metadata,omitempty"`
	Items           []LayerDeployment `json:"items"`
}

func (in *LayerDeployment) DeepCopyInto(out *LayerDeployment) {
	*out = *in
	out.ObjectMeta = *in.ObjectMeta.DeepCopy()
	out.Spec = in.Spec
	out.Spec.Coexistence = in.Spec.Coexistence
	if in.Spec.Coexistence.Enabled != nil {
		value := *in.Spec.Coexistence.Enabled
		out.Spec.Coexistence.Enabled = &value
	}
	if in.Spec.Coexistence.RetainInactiveLane != nil {
		value := *in.Spec.Coexistence.RetainInactiveLane
		out.Spec.Coexistence.RetainInactiveLane = &value
	}
	out.Status = in.Status
	if in.Status.Conditions != nil {
		out.Status.Conditions = append([]metav1.Condition(nil), in.Status.Conditions...)
	}
}

func (in *LayerDeployment) DeepCopy() *LayerDeployment {
	if in == nil {
		return nil
	}
	out := new(LayerDeployment)
	in.DeepCopyInto(out)
	return out
}

func (in *LayerDeployment) DeepCopyObject() runtime.Object {
	return in.DeepCopy()
}

func (in *LayerDeploymentList) DeepCopyInto(out *LayerDeploymentList) {
	*out = *in
	out.ListMeta = in.ListMeta
	if in.Items != nil {
		out.Items = make([]LayerDeployment, len(in.Items))
		for index := range in.Items {
			in.Items[index].DeepCopyInto(&out.Items[index])
		}
	}
}

func (in *LayerDeploymentList) DeepCopy() *LayerDeploymentList {
	if in == nil {
		return nil
	}
	out := new(LayerDeploymentList)
	in.DeepCopyInto(out)
	return out
}

func (in *LayerDeploymentList) DeepCopyObject() runtime.Object {
	return in.DeepCopy()
}
