# Project Matrix control-plane API

`LayerDeployment` is the cross-layer horizontal contract behind the OpenShift
AI UI. It is intentionally small: the end user selects the operating mode and
desired state; the controller owns dependency resolution and implementation.

Install the API definition only in a development cluster while the controller
is being built:

```bash
oc apply -f api/layerdeployment-crd.yaml
oc apply -f examples/gatekeeper-layerdeployment.yaml
```

The CRD alone does not perform installation. The controller scaffold now
reconciles the resource, writes a plan ConfigMap, and publishes explicit
conditions. It remains plan-only until the Gatekeeper adapter is installed; the
checked-in `gatekeeper/gatekeeper.sh` remains the inspectable
execution prototype.
