#!/usr/bin/env bash
set -euo pipefail

# Maintainer-only release builder. End users never run this script: they pull
# the resulting digest-locked images and apply the shipped manifests. Keeping
# the upload exclusions here prevents a release build from sending the
# vendored upstream tree, evidence archive, or local package cache to the
# cluster.

command -v oc >/dev/null || { echo "oc is required" >&2; exit 1; }

BUILD_NAMESPACE="${BUILD_NAMESPACE:-project-matrix-build}"
RELEASE_TAG="${RELEASE_TAG:-20261021-matrix}"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

start_binary_build() {
  local build_config="$1"
  oc start-build "${build_config}" \
    -n "${BUILD_NAMESPACE}" \
    --from-dir="${PROJECT_ROOT}" \
    --exclude='(^|/)(\.git|evidence|upstream|ui/frontend/node_modules|ui/frontend/src|ui/frontend/\.cache)(/|$)' \
    --wait
}

echo "Building Project Matrix release images with an excluded binary context"
echo "  namespace: ${BUILD_NAMESPACE}"
echo "  tag:       ${RELEASE_TAG}"

start_binary_build project-matrix-controller
start_binary_build project-matrix-gatekeeper
start_binary_build project-matrix-dashboard

for component in controller gatekeeper dashboard; do
  image="project-matrix-${component}"
  digest="$(oc get istag/${image}:${RELEASE_TAG} -n "${BUILD_NAMESPACE}" -o jsonpath='{.image.dockerImageReference}' 2>/dev/null || true)"
  test -n "${digest}" || { echo "missing output image for ${image}:${RELEASE_TAG}" >&2; exit 1; }
  printf '%s\n' "${component}: ${digest}"
done
