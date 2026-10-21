package main

import (
	"flag"
	"os"

	clientgoscheme "k8s.io/client-go/kubernetes/scheme"
	ctrl "sigs.k8s.io/controller-runtime"
	"sigs.k8s.io/controller-runtime/pkg/cache"
	"sigs.k8s.io/controller-runtime/pkg/healthz"
	"sigs.k8s.io/controller-runtime/pkg/log/zap"
	metricsserver "sigs.k8s.io/controller-runtime/pkg/metrics/server"

	matrixv1alpha1 "github.com/redhat-ai/project-matrix/controller/api/v1alpha1"
	"github.com/redhat-ai/project-matrix/controller/controllers"
)

func main() {
	var metricsAddr string
	var probeAddr string
	var enableLeaderElection bool
	flag.StringVar(&metricsAddr, "metrics-bind-address", ":8080", "The address the metric endpoint binds to.")
	flag.StringVar(&probeAddr, "health-probe-bind-address", ":8081", "The address the probe endpoint binds to.")
	flag.BoolVar(&enableLeaderElection, "leader-elect", false, "Enable leader election for controller manager.")
	flag.Parse()

	ctrl.SetLogger(zap.New(zap.UseFlagOptions(&zap.Options{})))

	scheme := clientgoscheme.Scheme
	if err := matrixv1alpha1.AddToScheme(scheme); err != nil {
		os.Exit(1)
	}

	mgr, err := ctrl.NewManager(ctrl.GetConfigOrDie(), ctrl.Options{
		Scheme: scheme,
		Cache: cache.Options{
			// Project Matrix owns only the namespaced control plane. Keeping
			// the informer cache namespaced is both leaner and a direct
			// defense against accidental cross-tenant observation.
			DefaultNamespaces: map[string]cache.Config{
				"matrix-system": {},
			},
		},
		Metrics:                metricsserver.Options{BindAddress: metricsAddr},
		HealthProbeBindAddress: probeAddr,
		LeaderElection:         enableLeaderElection,
		LeaderElectionID:       "project-matrix-controller",
	})
	if err != nil {
		os.Exit(1)
	}

	if err := (&controllers.LayerDeploymentReconciler{
		Client:                mgr.GetClient(),
		GatekeeperExecutorImage: os.Getenv("GATEKEEPER_EXECUTOR_IMAGE"),
	}).SetupWithManager(mgr); err != nil {
		os.Exit(1)
	}
	if err := mgr.AddHealthzCheck("healthz", healthz.Ping); err != nil {
		os.Exit(1)
	}
	if err := mgr.AddReadyzCheck("readyz", healthz.Ping); err != nil {
		os.Exit(1)
	}
	if err := mgr.Start(ctrl.SetupSignalHandler()); err != nil {
		os.Exit(1)
	}
}
