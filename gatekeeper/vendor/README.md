# Project Matrix vendor boundary

This directory contains the small, explicit asset set reused from the Saudi
Aramco MCP lifecycle work:

- Gateway backend `NetworkPolicy`;
- OIDC `AuthPolicy`;
- the OpenShift MCP fixture; and
- the inspectable MaaS/MCP round-trip runner.

The snapshot is used by Gatekeeper as a troubleshooting and evaluation aid. It
does not invoke the original bootstrap workflow, provision GPUs, install
cluster-wide operators, or create credentials. Changes should be reviewed
against the source Aramco lifecycle project and recorded in the Project Matrix
journal before promotion.
