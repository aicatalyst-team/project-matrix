# Project Matrix controller

This is the Kubernetes-native control-plane foundation for the horizontal
one-click deployments. It watches the `LayerDeployment` API, resolves the
canonical layer identity and the Production/Preview operating mode, writes an
auditable plan ConfigMap, and publishes status conditions.

With no `GATEKEEPER_EXECUTOR_IMAGE` configured, the first increment is
plan-only. It does not claim that Gatekeeper is installed and it does not mutate
shared Operators, Service Mesh, Gateway API, identity, or customer workloads.
When that image is explicitly configured, the Gatekeeper adapter turns an
accepted plan into a restricted Kubernetes Job and reflects its result as
`Installing`, `Ready`, or `Degraded`. The existing Gatekeeper shell remains the
inspectable troubleshooting prototype inside that image.

The executor image must contain `/opt/project-matrix/bin/run-gatekeeper`, the
checked-in Gatekeeper scripts, and the OpenShift CLI. The Job expects the
cluster-side service account `project-matrix-gatekeeper-runner`; its permissions
must be installed as a reviewed customer/platform policy, not silently
invented by the controller.

The reference policy is
`project-matrix/gatekeeper/manifests/gatekeeper-runner-rbac.yaml`. It is a separate
platform-admin action because the controller must not self-grant cross-namespace
or cluster-observation authority.

## Local verification

```bash
make test
make vet
```

The module uses controller-runtime and Kubernetes APIs, not an IBM runtime or
cloud service. Terraform and Ansible remain optional outer-layer automation.

## Optional execution mode

Build or mirror the executor image into the customer's approved registry, then
configure the controller deployment with:

```text
GATEKEEPER_EXECUTOR_IMAGE=<customer-registry>/project-matrix-gatekeeper:<pinned-version>
```

Leaving this variable unset is the safe plan-only mode for development and
dependency review.
