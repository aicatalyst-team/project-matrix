# Project Matrix release performance contract

The end-user path is an image pull plus a declarative OpenShift apply. It is
not a source upload, a Node or Go compilation, an operator installation, or an
unbounded model pull. Release builds are maintainer activity and are performed
once per immutable release; `deploy/build-release-images.sh` excludes the
vendored upstream checkout, evidence archive, local package cache, and source
files that are not required by the selected image build.

The shipped package is optimized along these boundaries:

- controller, Dashboard BFF, and Gatekeeper are separate runtime images with
  multi-stage builds; compilers and build tools do not enter runtime layers;
- all runtime references are digest locked in `deploy/IMAGE_RELEASE_LOCK.md`;
- the aggregate Kustomize package creates only the small Matrix control plane
  and does not rebuild or replace the operator-managed OpenShift AI Dashboard;
- the combined Dashboard host is an explicit maintainer/evaluation artifact,
  built once from the compatible Dashboard workspace and promoted by digest;
- Gatekeeper performs bounded preflight checks and fails closed before any
  expensive or unsafe install/evaluation work;
- lane selection is a CR update (`Production` by default, `Preview` only by
  explicit opt-in), not a second product or a second installation package.

## End-user acceptance

An installation is not release-ready unless the customer-facing instructions
require only:

```bash
oc apply -k .
```

followed by the single Dashboard action for the selected horizontal layer.
The release package must not require `oc start-build`, a local runtime,
`npm install`, `go build`, or access to the Project Matrix source repository.

The isolated Dashboard host evaluation scripts are intentionally separate from
that contract. They exist to validate the federated UI against a live cluster
until the package is accepted into the normal OpenShift AI Dashboard host
release.
