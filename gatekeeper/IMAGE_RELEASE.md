# Gatekeeper executor image release contract

The Gatekeeper executor is built from the Project Matrix source context. The
selected Saudi Aramco troubleshooting assets are vendored under
`gatekeeper/vendor/` with their provenance documented; the image has no runtime
dependency on `mempalace-openshift`.

## Build and verify

```bash
GATEKEEPER_IMAGE=registry.example.com/project-matrix/gatekeeper:0.1.0
podman build --pull=missing \
  -f gatekeeper/Containerfile \
  -t "${GATEKEEPER_IMAGE}" \
  /Users/geraldtrotman/Virtualenvs/project-matrix

podman run --rm --entrypoint /opt/project-matrix/bin/run-gatekeeper \
  "${GATEKEEPER_IMAGE}" --help
```

The image must run as a non-root user and expose
`/opt/project-matrix/bin/run-gatekeeper`. The entrypoint retains the original
Gatekeeper shell workflow and publishes the evidence ConfigMap after the run.

## Promote to a customer registry

Push only to the registry approved for the target OpenShift environment, then
record the immutable digest returned by the registry:

```bash
podman push "${GATEKEEPER_IMAGE}"
podman image inspect "${GATEKEEPER_IMAGE}" --format '{{index .RepoDigests 0}}'
```

Configure the controller with the full digest reference, for example:

```text
GATEKEEPER_EXECUTOR_IMAGE=registry.example.com/project-matrix/gatekeeper@sha256:<registry-digest>
```

Do not promote the local `:dev` tag or a floating `:latest` tag into a
production profile. The production lane requires a pinned image, support
classification, source revision, and promotion record.

## Profile packaging

The OpenShift-native profile is the Kustomize package in this directory. It
contains the Gatekeeper namespace and reviewed runner RBAC. It is intended to be
applied by the Project Matrix controller/OLM/GitOps installation path, not by
the end user:

```bash
oc apply -k /Users/geraldtrotman/Virtualenvs/project-matrix/gatekeeper/manifests
```

The current profile deliberately does not grant optional fixture permissions
or install cluster-wide Operators.
