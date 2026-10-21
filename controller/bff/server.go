package bff

import (
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"

	matrixv1alpha1 "github.com/redhat-ai/project-matrix/controller/api/v1alpha1"
	apierrors "k8s.io/apimachinery/pkg/api/errors"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/types"
	"sigs.k8s.io/controller-runtime/pkg/client"
)

const (
	// RoutePath is the browser-facing path used by the federated dashboard
	// module. ODH Dashboard rewrites this prefix before proxying to the BFF.
	RoutePath = "/project-matrix/api/v1/layerdeployments/gatekeeper"
	// ProxyRoutePath is the path received after the ODH Dashboard proxy
	// rewrites /project-matrix/api to /api.
	ProxyRoutePath = "/api/v1/layerdeployments/gatekeeper"
)

const (
	defaultNamespace     = "matrix-system"
	defaultName          = "gatekeeper"
	defaultUserHeader    = "Authorization"
	retryTokenAnnotation = "project-matrix.redhat.com/retry-token"
)

// Server is the deliberately narrow dashboard authorization/transport
// boundary. It is not a second Project Matrix controller and it never invokes
// an installer, Job, or Aramock workflow.
type Server struct {
	Client     client.Client
	Namespace  string
	Name       string
	UserHeader string
}

type applyRequest struct {
	Namespace string       `json:"namespace"`
	Spec      gatekeeperSpec `json:"spec"`
}

type gatekeeperSpec struct {
	Layer        string          `json:"layer"`
	CodeName     string          `json:"codeName"`
	Mode         string          `json:"mode"`
	DesiredState string          `json:"desiredState"`
	Profile      string          `json:"profile"`
	Coexistence  coexistenceSpec `json:"coexistence"`
}

type coexistenceSpec struct {
	Enabled            bool `json:"enabled"`
	RetainInactiveLane bool `json:"retainInactiveLane"`
}

type responseEnvelope struct {
	Data any `json:"data"`
}

type errorEnvelope struct {
	Error apiError `json:"error"`
}

type apiError struct {
	Code    string `json:"code"`
	Message string `json:"message"`
}

func NewServer(kubeClient client.Client, namespace, name, userHeader string) *Server {
	if namespace == "" {
		namespace = defaultNamespace
	}
	if name == "" {
		name = defaultName
	}
	if userHeader == "" {
		userHeader = defaultUserHeader
	}
	return &Server{Client: kubeClient, Namespace: namespace, Name: name, UserHeader: userHeader}
}

func (s *Server) ServeHTTP(writer http.ResponseWriter, request *http.Request) {
	if request.URL.Path != RoutePath && request.URL.Path != ProxyRoutePath {
		s.writeError(writer, http.StatusNotFound, "NotFound", "Project Matrix route not found")
		return
	}
	if !s.authenticated(request) {
		s.writeError(writer, http.StatusUnauthorized, "Unauthenticated", "The dashboard identity is required")
		return
	}

	switch request.Method {
	case http.MethodGet:
		s.get(writer, request)
	case http.MethodPost:
		s.apply(writer, request)
	default:
		writer.Header().Set("Allow", "GET, POST")
		s.writeError(writer, http.StatusMethodNotAllowed, "MethodNotAllowed", "Only GET and POST are supported")
	}
}

func (s *Server) authenticated(request *http.Request) bool {
	value := strings.TrimSpace(request.Header.Get(s.UserHeader))
	if s.UserHeader == "Authorization" {
		return strings.HasPrefix(value, "Bearer ") && len(strings.TrimSpace(strings.TrimPrefix(value, "Bearer "))) > 0
	}
	return value != ""
}

func (s *Server) get(writer http.ResponseWriter, request *http.Request) {
	namespace, ok := s.validateNamespaceQuery(writer, request)
	if !ok {
		return
	}

	deployment := &matrixv1alpha1.LayerDeployment{}
	err := s.Client.Get(request.Context(), types.NamespacedName{Name: s.Name, Namespace: namespace}, deployment)
	if apierrors.IsNotFound(err) {
		s.writeJSON(writer, http.StatusOK, responseEnvelope{Data: nil})
		return
	}
	if err != nil {
		s.writeError(writer, http.StatusInternalServerError, "ReadFailed", "Unable to read the Project Matrix deployment")
		return
	}
	s.writeJSON(writer, http.StatusOK, responseEnvelope{Data: deployment})
}

func (s *Server) apply(writer http.ResponseWriter, request *http.Request) {
	requestBody, err := decodeApplyRequest(writer, request)
	if err != nil {
		s.writeError(writer, http.StatusBadRequest, "InvalidRequest", err.Error())
		return
	}
	if requestBody.Namespace != s.Namespace {
		s.writeError(writer, http.StatusBadRequest, "InvalidNamespace", fmt.Sprintf("namespace must be %q", s.Namespace))
		return
	}
	if err := validateGatekeeperSpec(requestBody.Spec); err != nil {
		s.writeError(writer, http.StatusBadRequest, "InvalidGatekeeperIntent", err.Error())
		return
	}

	ctx := request.Context()
	key := types.NamespacedName{Name: s.Name, Namespace: s.Namespace}
	current := &matrixv1alpha1.LayerDeployment{}
	err = s.Client.Get(ctx, key, current)
	if apierrors.IsNotFound(err) {
		created := &matrixv1alpha1.LayerDeployment{
			TypeMeta: metav1.TypeMeta{
				APIVersion: matrixv1alpha1.GroupVersion.String(),
				Kind:       "LayerDeployment",
			},
			ObjectMeta: metav1.ObjectMeta{
				Name:      s.Name,
				Namespace: s.Namespace,
				Annotations: map[string]string{
					retryTokenAnnotation: time.Now().UTC().Format(time.RFC3339Nano),
				},
				Labels: map[string]string{
					"app.kubernetes.io/part-of":          "project-matrix",
					"project-matrix.redhat.com/layer":     "gateway",
					"project-matrix.redhat.com/code-name": "gatekeeper",
				},
			},
			Spec: toLayerDeploymentSpec(requestBody.Spec),
		}
		if err := s.Client.Create(ctx, created); err != nil {
			if apierrors.IsAlreadyExists(err) {
				s.writeError(writer, http.StatusConflict, "ApplyConflict", "The Gatekeeper deployment changed while it was being applied")
				return
			}
			s.writeError(writer, http.StatusInternalServerError, "CreateFailed", "Unable to create the Project Matrix deployment")
			return
		}
		s.writeJSON(writer, http.StatusCreated, responseEnvelope{Data: created})
		return
	}
	if err != nil {
		s.writeError(writer, http.StatusInternalServerError, "ReadFailed", "Unable to read the Project Matrix deployment")
		return
	}

	original := current.DeepCopy()
	current.Spec = toLayerDeploymentSpec(requestBody.Spec)
	if current.Annotations == nil {
		current.Annotations = map[string]string{}
	}
	current.Annotations[retryTokenAnnotation] = time.Now().UTC().Format(time.RFC3339Nano)
	if err := s.Client.Patch(ctx, current, client.MergeFrom(original)); err != nil {
		if apierrors.IsConflict(err) {
			s.writeError(writer, http.StatusConflict, "ApplyConflict", "The Gatekeeper deployment changed while it was being applied")
			return
		}
		s.writeError(writer, http.StatusInternalServerError, "UpdateFailed", "Unable to update the Project Matrix deployment")
		return
	}
	s.writeJSON(writer, http.StatusOK, responseEnvelope{Data: current})
}

func decodeApplyRequest(writer http.ResponseWriter, request *http.Request) (applyRequest, error) {
	decoder := json.NewDecoder(http.MaxBytesReader(writer, request.Body, 64*1024))
	decoder.DisallowUnknownFields()

	var decoded applyRequest
	if err := decoder.Decode(&decoded); err != nil {
		return applyRequest{}, errors.New("request body must be a valid Project Matrix intent")
	}
	var extra any
	if err := decoder.Decode(&extra); !errors.Is(err, io.EOF) {
		return applyRequest{}, errors.New("request body must contain exactly one JSON object")
	}
	return decoded, nil
}

func validateGatekeeperSpec(spec gatekeeperSpec) error {
	if spec.Layer != "Gateway" || spec.CodeName != "Gatekeeper" {
		return errors.New("only the Gateway/The Gatekeeper layer is exposed by this endpoint")
	}
	if spec.Mode != "Production" && spec.Mode != "Preview" {
		return errors.New("mode must be Production or Preview")
	}
	if spec.DesiredState != "Enabled" {
		return errors.New("desiredState must be Enabled")
	}
	expectedProfile := "gateway-production"
	if spec.Mode == "Preview" {
		expectedProfile = "gateway-evaluation"
	}
	if spec.Profile != expectedProfile {
		return fmt.Errorf("profile must be %q for %s mode", expectedProfile, spec.Mode)
	}
	if !spec.Coexistence.Enabled || !spec.Coexistence.RetainInactiveLane {
		return errors.New("coexistence must retain the inactive lane")
	}
	return nil
}

func toLayerDeploymentSpec(spec gatekeeperSpec) matrixv1alpha1.LayerDeploymentSpec {
	return matrixv1alpha1.LayerDeploymentSpec{
		Layer:        spec.Layer,
		CodeName:     spec.CodeName,
		Mode:         spec.Mode,
		DesiredState: spec.DesiredState,
		Profile:      spec.Profile,
		Coexistence: matrixv1alpha1.CoexistenceSpec{
			Enabled:            boolPointer(spec.Coexistence.Enabled),
			RetainInactiveLane: boolPointer(spec.Coexistence.RetainInactiveLane),
		},
	}
}

func boolPointer(value bool) *bool {
	return &value
}

func (s *Server) validateNamespaceQuery(writer http.ResponseWriter, request *http.Request) (string, bool) {
	namespace := request.URL.Query().Get("namespace")
	if namespace == "" {
		namespace = s.Namespace
	}
	if namespace != s.Namespace {
		s.writeError(writer, http.StatusBadRequest, "InvalidNamespace", fmt.Sprintf("namespace must be %q", s.Namespace))
		return "", false
	}
	return namespace, true
}

func (s *Server) writeJSON(writer http.ResponseWriter, status int, body any) {
	writer.Header().Set("Content-Type", "application/json")
	writer.WriteHeader(status)
	_ = json.NewEncoder(writer).Encode(body)
}

func (s *Server) writeError(writer http.ResponseWriter, status int, code, message string) {
	s.writeJSON(writer, status, errorEnvelope{Error: apiError{Code: code, Message: message}})
}

var _ http.Handler = (*Server)(nil)
