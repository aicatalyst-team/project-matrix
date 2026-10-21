package adapter

import (
	"fmt"

	matrixv1alpha1 "github.com/redhat-ai/project-matrix/controller/api/v1alpha1"
	batchv1 "k8s.io/api/batch/v1"
	corev1 "k8s.io/api/core/v1"
	"k8s.io/apimachinery/pkg/api/resource"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/labels"
)

const (
	LayerLabel       = "project-matrix.redhat.com/layer"
	CodeNameLabel    = "project-matrix.redhat.com/code-name"
	DeploymentLabel  = "project-matrix.redhat.com/layer-deployment"
	ExecutorLabel    = "project-matrix.redhat.com/executor"
	GatekeeperExecutor = "gatekeeper"
)

// GatekeeperJob returns the execution unit for the Gateway layer. It does not
// embed customer endpoints or credentials; those are supplied later through
// cluster-side Secret references and profile configuration.
func GatekeeperJob(deployment *matrixv1alpha1.LayerDeployment, image string) *batchv1.Job {
	profile := "innovation"
	args := []string{"--profile", profile, "all"}
	if deployment.Spec.Mode == "Production" {
		profile = "production"
		args = []string{"--profile", profile, "all"}
	}

	labelsForJob := labels.Set{
		LayerLabel:                      deployment.Spec.Layer,
		CodeNameLabel:                   deployment.Spec.CodeName,
		DeploymentLabel:                 deployment.Name,
		ExecutorLabel:                   GatekeeperExecutor,
		"project-matrix.redhat.com/mode": deployment.Spec.Mode,
	}
	annotationsForJob := map[string]string{}
	if retryToken := deployment.Annotations["project-matrix.redhat.com/retry-token"]; retryToken != "" {
		annotationsForJob["project-matrix.redhat.com/retry-token"] = retryToken
	}
	backoffLimit := int32(0)
	activeDeadlineSeconds := int64(3600)
	trueValue := true
	falseValue := false
	env := []corev1.EnvVar{
		{Name: "GATEKEEPER_RUN_ROOT", Value: "/var/lib/project-matrix/runs"},
		{Name: "PROJECT_MATRIX_LAYER_DEPLOYMENT", Value: deployment.Name},
		{Name: "PROJECT_MATRIX_EVIDENCE_CONFIGMAP", Value: fmt.Sprintf("project-matrix-evidence-%s", deployment.Name)},
		{Name: "PROJECT_MATRIX_EVIDENCE_NAMESPACE", ValueFrom: &corev1.EnvVarSource{FieldRef: &corev1.ObjectFieldSelector{FieldPath: "metadata.namespace"}}},
	}
	if deployment.Spec.Mode == "Preview" {
		// Preview is an isolated upstream release, not the Red Hat-managed
		// Gateway. The entrypoint installs the pinned release first, then runs
		// Gatekeeper against the isolated resources.
		args = []string{"preview-install"}
		env = append(env,
			corev1.EnvVar{Name: "GATEKEEPER_PREVIEW_SOURCE", Value: "upstream"},
			corev1.EnvVar{Name: "GATEKEEPER_GATEWAY_NAMESPACE", Value: "mcp-gateway-preview"},
			corev1.EnvVar{Name: "GATEKEEPER_GATEWAY_NAME", Value: "mcp-gateway-preview"},
			corev1.EnvVar{Name: "GATEKEEPER_GATEWAY_CLASS", Value: "openshift-default"},
			corev1.EnvVar{Name: "GATEKEEPER_GATEWAY_EXTENSION_NAME", Value: "mcp-gateway-preview-extension"},
			corev1.EnvVar{Name: "GATEKEEPER_GATEWAY_ROUTE_NAME", Value: "mcp-gateway-preview"},
			corev1.EnvVar{Name: "GATEKEEPER_GATEWAY_EXPOSURE_MODE", Value: "openshift-route"},
			corev1.EnvVar{Name: "GATEKEEPER_EXPECTED_GATEWAY_SERVICE_TYPE", Value: "ClusterIP"},
			corev1.EnvVar{Name: "GATEKEEPER_DNS_RECORD_NAME", Value: "mcp-gateway-preview"},
			corev1.EnvVar{Name: "GATEKEEPER_OPERATOR_NAMESPACES", Value: "mcp-gateway-preview,mcp-gateway-system,openshift-operators,redhat-ods-operator"},
		)
	}

	return &batchv1.Job{
		ObjectMeta: metav1.ObjectMeta{
			Name:        fmt.Sprintf("project-matrix-gatekeeper-%s", deployment.Name),
			Namespace:   deployment.Namespace,
			Labels:      labelsForJob,
			Annotations: annotationsForJob,
		},
		Spec: batchv1.JobSpec{
			BackoffLimit:          &backoffLimit,
			ActiveDeadlineSeconds: &activeDeadlineSeconds,
			Template: corev1.PodTemplateSpec{
				ObjectMeta: metav1.ObjectMeta{Labels: labelsForJob},
				Spec: corev1.PodSpec{
					RestartPolicy:                 corev1.RestartPolicyNever,
					AutomountServiceAccountToken:  &trueValue,
					EnableServiceLinks:            &falseValue,
					ServiceAccountName:            "project-matrix-gatekeeper-runner",
					TerminationGracePeriodSeconds: int64ptr(30),
					SecurityContext: &corev1.PodSecurityContext{
						RunAsNonRoot:   &trueValue,
						SeccompProfile: &corev1.SeccompProfile{Type: corev1.SeccompProfileTypeRuntimeDefault},
					},
					Containers: []corev1.Container{{
						Name:            "gatekeeper",
						Image:           image,
						ImagePullPolicy: corev1.PullIfNotPresent,
						Command:         []string{"/opt/project-matrix/bin/run-gatekeeper"},
						Args:            args,
						Env:             env,
						Resources: corev1.ResourceRequirements{
							Requests: corev1.ResourceList{
								corev1.ResourceCPU:    resourceQuantity("10m"),
								corev1.ResourceMemory: resourceQuantity("64Mi"),
							},
							Limits: corev1.ResourceList{
								corev1.ResourceCPU:    resourceQuantity("500m"),
								corev1.ResourceMemory: resourceQuantity("512Mi"),
							},
						},
						SecurityContext: &corev1.SecurityContext{
							AllowPrivilegeEscalation: &falseValue,
							Capabilities:             &corev1.Capabilities{Drop: []corev1.Capability{"ALL"}},
							ReadOnlyRootFilesystem:   &falseValue,
						},
					}},
				},
			},
		},
	}
}

func int64ptr(value int64) *int64 { return &value }

func resourceQuantity(value string) resource.Quantity {
	return resource.MustParse(value)
}
