#!/usr/bin/env bash
set -euo pipefail

# Validate the contract consumed by the OpenShift AI Dashboard host. This is
# intentionally independent of the host repository: Project Matrix remains its
# own deliverable and the host consumes it as a workspace package at build
# time.

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PROJECT_ROOT=$(cd "${SCRIPT_DIR}/.." && pwd)
REQUIRE_BUILD=false
DIST_DIR_OVERRIDE=''

usage() {
  cat <<'EOF'
Usage: validate-host-integration.sh [--require-build] [--dist-dir PATH]

Validate the Project Matrix package metadata, extension declarations, BFF
proxy contract, and (optionally) the built Module Federation artifact.
EOF
}

while (($#)); do
  case "$1" in
    --require-build)
      REQUIRE_BUILD=true
      ;;
    --dist-dir)
      shift
      if (($# == 0)); then
        echo "error: --dist-dir requires a path" >&2
        exit 2
      fi
      DIST_DIR_OVERRIDE=$1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "error: unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

PACKAGE_JSON="${SCRIPT_DIR}/package.json"
EXTENSIONS_TS="${SCRIPT_DIR}/extensions.ts"
FRONTEND_DIR="${SCRIPT_DIR}/frontend"

node - "${PACKAGE_JSON}" "${EXTENSIONS_TS}" "${FRONTEND_DIR}" "${REQUIRE_BUILD}" "${DIST_DIR_OVERRIDE}" <<'NODE'
const fs = require('fs');
const path = require('path');

const [packagePath, extensionsPath, frontendDir, requireBuild, distDirOverride] = process.argv.slice(2);
const pkg = JSON.parse(fs.readFileSync(packagePath, 'utf8'));
const extensions = fs.readFileSync(extensionsPath, 'utf8');
const extensionDeclarationsPath = path.join(frontendDir, 'src', 'odh', 'extensions.ts');
const extensionDeclarations = fs.readFileSync(extensionDeclarationsPath, 'utf8');
const errors = [];

const expect = (condition, message) => {
  if (!condition) errors.push(message);
};

const mf = pkg['module-federation'] || {};
const proxy = Array.isArray(mf.proxy) ? mf.proxy : [];
const proxyEntry = proxy.find((entry) => entry.path === '/project-matrix/api');
const service = mf.service || {};
const local = mf.local || {};

expect(pkg.name === '@odh-dashboard/project-matrix', `package name must be @odh-dashboard/project-matrix (got ${pkg.name})`);
expect(pkg.exports && pkg.exports['./extensions'] === './extensions.ts', 'package must export ./extensions from ./extensions.ts');
expect(mf.name === 'projectMatrix', `module federation name must be projectMatrix (got ${mf.name})`);
expect(mf.remoteEntry === '/remoteEntry.js', 'module federation remoteEntry must be /remoteEntry.js');
expect(mf.authorize === true, 'module federation authorize must remain enabled');
expect(proxyEntry && proxyEntry.pathRewrite === '/api', 'proxy must map /project-matrix/api to /api');
expect(local.host === 'localhost' && local.port === 9109, 'local module federation endpoint must be localhost:9109');
expect(service.name === 'project-matrix-dashboard-bff', 'BFF service name must be project-matrix-dashboard-bff');
expect(service.namespace === 'matrix-system', 'BFF service namespace must be matrix-system');
expect(service.port === 8082, 'BFF service port must be 8082');

for (const required of [
  "export { default } from './frontend/src/odh/extensions'",
]) {
  expect(fs.readFileSync(extensionsPath, 'utf8').includes(required), `extensions.ts must contain: ${required}`);
}

for (const required of [
  "const PROJECT_MATRIX = 'projectMatrix'",
  'id: PROJECT_MATRIX',
  "title: 'Agentic Platform'",
  "title: 'Red Hat AI: Agentic Strategy'",
  "href: '/project-matrix'",
  "path: '/project-matrix/*'",
]) {
  expect(extensionDeclarations.includes(required), `extension declarations must contain: ${required}`);
}

const buildDir = distDirOverride || path.join(frontendDir, 'dist');
if (requireBuild === 'true') {
  for (const artifact of ['remoteEntry.js', 'mf-manifest.json', 'index.html']) {
    expect(fs.existsSync(path.join(buildDir, artifact)), `built artifact is missing: frontend/dist/${artifact}`);
  }
  const manifestPath = path.join(buildDir, 'mf-manifest.json');
  if (fs.existsSync(manifestPath)) {
    const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
    expect(manifest.name === 'projectMatrix', `built manifest name must be projectMatrix (got ${manifest.name})`);
    expect(manifest.metaData && manifest.metaData.remoteEntry && manifest.metaData.remoteEntry.name === 'remoteEntry.js', 'built manifest must point to remoteEntry.js');
  }
}

if (errors.length) {
  console.error('Project Matrix Dashboard host-integration validation failed:');
  for (const error of errors) console.error(`- ${error}`);
  process.exit(1);
}

console.log(`Project Matrix Dashboard host-integration contract passed${requireBuild === 'true' ? ' with built artifacts' : ''}.`);
console.log(`- federated module: ${mf.name}`);
console.log(`- navigation: Agentic Platform / Red Hat AI: Agentic Strategy`);
console.log(`- BFF: ${service.namespace}/${service.name}:${service.port}`);
NODE
