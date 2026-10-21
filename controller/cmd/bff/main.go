package main

import (
	"context"
	"flag"
	"log"
	"net/http"
	"os"
	"time"

	clientgoscheme "k8s.io/client-go/kubernetes/scheme"
	ctrl "sigs.k8s.io/controller-runtime"
	"sigs.k8s.io/controller-runtime/pkg/client"

	matrixv1alpha1 "github.com/redhat-ai/project-matrix/controller/api/v1alpha1"
	"github.com/redhat-ai/project-matrix/controller/bff"
)

func main() {
	var bindAddress string
	flag.StringVar(&bindAddress, "bind-address", envOrDefault("BFF_BIND_ADDRESS", ":8082"), "Address for the Project Matrix dashboard BFF")
	flag.Parse()

	scheme := clientgoscheme.Scheme
	if err := matrixv1alpha1.AddToScheme(scheme); err != nil {
		log.Fatalf("register Project Matrix API: %v", err)
	}
	config, err := ctrl.GetConfig()
	if err != nil {
		log.Fatalf("load Kubernetes configuration: %v", err)
	}
	kubeClient, err := client.New(config, client.Options{Scheme: scheme})
	if err != nil {
		log.Fatalf("create Kubernetes client: %v", err)
	}

	projectMatrixServer := bff.NewServer(
		kubeClient,
		envOrDefault("BFF_NAMESPACE", "matrix-system"),
		envOrDefault("BFF_NAME", "gatekeeper"),
		envOrDefault("BFF_USER_HEADER", "Authorization"),
	)
	mux := http.NewServeMux()
	mux.Handle(bff.RoutePath, projectMatrixServer)
	mux.Handle(bff.ProxyRoutePath, projectMatrixServer)
	mux.HandleFunc("/healthz", func(writer http.ResponseWriter, _ *http.Request) {
		writer.WriteHeader(http.StatusOK)
	})
	if staticDirectory := os.Getenv("BFF_STATIC_DIR"); staticDirectory != "" {
		mux.Handle("/", http.FileServer(http.Dir(staticDirectory)))
	}

	httpServer := &http.Server{
		Addr:              bindAddress,
		Handler:           mux,
		ReadHeaderTimeout: 10 * time.Second,
		ReadTimeout:       30 * time.Second,
		WriteTimeout:      30 * time.Second,
		IdleTimeout:       60 * time.Second,
	}

	serverErrors := make(chan error, 1)
	go func() {
		if listenErr := httpServer.ListenAndServe(); listenErr != nil && listenErr != http.ErrServerClosed {
			serverErrors <- listenErr
		}
	}()

	select {
	case err := <-serverErrors:
		log.Fatalf("Project Matrix BFF stopped: %v", err)
	case <-ctrl.SetupSignalHandler().Done():
		shutdownContext, cancel := context.WithTimeout(context.Background(), 10*time.Second)
		defer cancel()
		if err := httpServer.Shutdown(shutdownContext); err != nil {
			log.Printf("Project Matrix BFF shutdown: %v", err)
		}
	}
}

func envOrDefault(name, fallback string) string {
	if value := os.Getenv(name); value != "" {
		return value
	}
	return fallback
}
