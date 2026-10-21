package controllers

import (
	"context"
	"encoding/json"
	"fmt"
	"reflect"
	"time"

	matrixv1alpha1 "github.com/redhat-ai/project-matrix/controller/api/v1alpha1"
	"github.com/redhat-ai/project-matrix/controller/internal/adapter"
	"github.com/redhat-ai/project-matrix/controller/internal/dependency"
	"github.com/redhat-ai/project-matrix/controller/internal/plan"
	batchv1 "k8s.io/api/batch/v1"
	corev1 "k8s.io/api/core/v1"
	apierrors "k8s.io/apimachinery/pkg/api/errors"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/types"
	"sigs.k8s.io/controller-runtime/pkg/builder"
	"sigs.k8s.io/controller-runtime/pkg/client"
	"sigs.k8s.io/controller-runtime/pkg/controller/controllerutil"
	"sigs.k8s.io/controller-runtime/pkg/manager"
	"sigs.k8s.io/controller-runtime/pkg/reconcile"
)

const (
	planConfigMapPrefix     = "project-matrix-plan-"
	evidenceConfigMapPrefix = "project-matrix-evidence-"
	planLabel               = "project-matrix.redhat.com/plan"
)

type LayerDeploymentReconciler struct {
	client.Client
	GatekeeperExecutorImage string
}

func (r *LayerDeploymentReconciler) Reconcile(ctx context.Context, request reconcile.Request) (reconcile.Result, error) {
	var deployment matrixv1alpha1.LayerDeployment
	if err := r.Get(ctx, request.NamespacedName, &deployment); err != nil {
		return reconcile.Result{}, client.IgnoreNotFound(err)
	}

	computed := plan.Build(deployment.Spec)
	if computed.Phase == "Preflighting" {
		var deployments matrixv1alpha1.LayerDeploymentList
		if err := r.List(ctx, &deployments); err != nil {
			return reconcile.Result{}, err
		}
		intents := make([]dependency.Intent, 0, len(deployments.Items))
		for _, candidate := range deployments.Items {
			intents = append(intents, dependency.IntentFromDeployment(candidate))
		}
		for _, conflict := range dependency.Resolve(intents) {
			if dependency.Involves(conflict, deployment.Namespace, deployment.Name) {
				computed = plan.Block(computed, "DependencyConflict", fmt.Sprintf("%s; no cluster mutation was attempted", conflict.Message))
				break
			}
		}
	}
	if computed.Phase == "Preflighting" && deployment.Spec.Layer == "Gateway" && r.GatekeeperExecutorImage != "" {
		job, created, err := r.ensureGatekeeperJob(ctx, &deployment)
		if err != nil {
			return reconcile.Result{}, err
		}
		computed = executionState(computed, job, created)
	}
	if err := r.persistPlan(ctx, &deployment, computed); err != nil {
		return reconcile.Result{}, err
	}

	evidenceRef := planConfigMapPrefix + deployment.Name
	if r.GatekeeperExecutorImage != "" && deployment.Spec.Layer == "Gateway" {
		evidenceRef = evidenceConfigMapPrefix + deployment.Name
	}
	original := deployment.DeepCopy()
	deployment.Status = matrixv1alpha1.LayerDeploymentStatus{
		Phase:           computed.Phase,
		ActiveMode:      computed.ActiveMode,
		Conditions:      preserveTransitionTimes(original.Status.Conditions, computed.Conditions),
		EvidenceRef:     evidenceRef,
		SupportBoundary: computed.SupportBoundary,
	}
	if !reflect.DeepEqual(original.Status, deployment.Status) {
		if err := r.Status().Patch(ctx, &deployment, client.MergeFrom(original)); err != nil {
			return reconcile.Result{}, err
		}
	}

	return reconcile.Result{}, nil
}

func (r *LayerDeploymentReconciler) ensureGatekeeperJob(ctx context.Context, deployment *matrixv1alpha1.LayerDeployment) (*batchv1.Job, bool, error) {
	desired := adapter.GatekeeperJob(deployment, r.GatekeeperExecutorImage)
	if err := controllerutil.SetControllerReference(deployment, desired, r.Scheme()); err != nil {
		return nil, false, err
	}

	existing := &batchv1.Job{}
	key := types.NamespacedName{Name: desired.Name, Namespace: desired.Namespace}
	if err := r.Get(ctx, key, existing); err != nil {
		if !apierrors.IsNotFound(err) {
			return nil, false, err
		}
		if err := r.Create(ctx, desired); err != nil {
			return nil, false, err
		}
		return desired, true, nil
	}
	jobChanged := existing.Labels[adapter.DeploymentLabel] != desired.Labels[adapter.DeploymentLabel] ||
		existing.Labels["project-matrix.redhat.com/mode"] != desired.Labels["project-matrix.redhat.com/mode"] ||
		existing.Annotations["project-matrix.redhat.com/retry-token"] != desired.Annotations["project-matrix.redhat.com/retry-token"] ||
		existing.Spec.Template.Spec.Containers[0].Image != desired.Spec.Template.Spec.Containers[0].Image ||
		!reflect.DeepEqual(existing.Spec.Template.Spec.Containers[0].Args, desired.Spec.Template.Spec.Containers[0].Args)
	if jobChanged {
		// Jobs are immutable after execution. A retry or a Production/Preview
		// lane switch must replace the terminal Job so the UI's single click
		// remains repeatable without requiring manual cleanup.
		// Foreground propagation removes the Job's owned Pod before the
		// replacement is created. Without this, a lane switch can leave an
		// orphaned failed Pod with the replacement Job's name/labels, which
		// makes status and diagnostics ambiguous.
		if err := r.Delete(ctx, existing, client.PropagationPolicy(metav1.DeletePropagationForeground)); err != nil {
			return nil, false, err
		}
		return desired, false, nil
	}
	return existing, false, nil
}

func executionState(computed plan.Plan, job *batchv1.Job, created bool) plan.Plan {
	computed.Execution = "job-running"
	computed.Phase = "Installing"
	if created {
		computed.Execution = "job-created"
	}
	if job.Status.Succeeded > 0 {
		computed.Execution = "job-succeeded"
		computed.Phase = "Ready"
		computed.Message = "Gatekeeper execution Job completed successfully; validation evidence is available from the Job run."
		setCondition(&computed, plan.ConditionAdapterReady, metav1.ConditionTrue, "JobSucceeded", computed.Message)
		setCondition(&computed, plan.ConditionReady, metav1.ConditionTrue, "JobSucceeded", computed.Message)
		return computed
	}
	if job.Status.Failed > 0 {
		computed.Execution = "job-failed"
		computed.Phase = "Degraded"
		computed.Message = "Gatekeeper execution Job failed; inspect the Job logs and diagnostics before retrying."
		setCondition(&computed, plan.ConditionAdapterReady, metav1.ConditionFalse, "JobFailed", computed.Message)
		setCondition(&computed, plan.ConditionReady, metav1.ConditionFalse, "JobFailed", computed.Message)
		return computed
	}
	setCondition(&computed, plan.ConditionAdapterReady, metav1.ConditionFalse, "JobRunning", "Gatekeeper execution Job exists and has not completed.")
	setCondition(&computed, plan.ConditionReady, metav1.ConditionFalse, "JobRunning", "The Gateway layer is not Ready until the Gatekeeper execution Job completes.")
	return computed
}

func setCondition(computed *plan.Plan, conditionType string, status metav1.ConditionStatus, reason, message string) {
	for index := range computed.Conditions {
		if computed.Conditions[index].Type == conditionType {
			computed.Conditions[index].Status = status
			computed.Conditions[index].Reason = reason
			computed.Conditions[index].Message = message
			return
		}
	}
	computed.Conditions = append(computed.Conditions, metav1.Condition{
		Type:    conditionType,
		Status:  status,
		Reason:  reason,
		Message: message,
	})
}

func (r *LayerDeploymentReconciler) persistPlan(ctx context.Context, deployment *matrixv1alpha1.LayerDeployment, computed plan.Plan) error {
	payload, err := json.MarshalIndent(computed, "", "  ")
	if err != nil {
		return err
	}

	planConfigMap := &corev1.ConfigMap{}
	key := types.NamespacedName{Name: planConfigMapPrefix + deployment.Name, Namespace: deployment.Namespace}
	if err := r.Get(ctx, key, planConfigMap); client.IgnoreNotFound(err) != nil {
		return err
	}
	planConfigMap.Name = key.Name
	planConfigMap.Namespace = key.Namespace
	_, err = controllerutil.CreateOrUpdate(ctx, r.Client, planConfigMap, func() error {
		planConfigMap.Labels = map[string]string{planLabel: deployment.Name}
		planConfigMap.Data = map[string]string{
			"plan.json":   string(payload),
			"generatedAt": time.Now().UTC().Format(time.RFC3339),
		}
		return controllerutil.SetControllerReference(deployment, planConfigMap, r.Scheme())
	})
	return err
}

func preserveTransitionTimes(previous, desired []metav1.Condition) []metav1.Condition {
	result := make([]metav1.Condition, len(desired))
	for index, next := range desired {
		next.LastTransitionTime = metav1.Now()
		for _, old := range previous {
			if old.Type == next.Type && old.Status == next.Status && old.Reason == next.Reason {
				next.LastTransitionTime = old.LastTransitionTime
				break
			}
		}
		result[index] = next
	}
	return result
}

func (r *LayerDeploymentReconciler) SetupWithManager(manager manager.Manager) error {
	return builder.ControllerManagedBy(manager).
		For(&matrixv1alpha1.LayerDeployment{}).
		Owns(&batchv1.Job{}).
		Complete(r)
}
