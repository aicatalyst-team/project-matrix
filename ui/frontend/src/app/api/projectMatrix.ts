import {
  APIOptions,
  handleRestFailures,
  isModArchResponse,
  restCREATE,
  restGET,
} from 'mod-arch-core';

export type DeploymentMode = 'Production' | 'Preview';

export type LayerDeploymentCondition = {
  type: string;
  status: 'True' | 'False' | 'Unknown';
  reason?: string;
  message?: string;
  lastTransitionTime?: string;
};

export type LayerDeployment = {
  apiVersion: 'project-matrix.redhat.com/v1alpha1';
  kind: 'LayerDeployment';
  metadata: {
    name: string;
    namespace: string;
    creationTimestamp?: string;
  };
  spec: {
    layer: 'Gateway';
    codeName: 'Gatekeeper';
    mode: DeploymentMode;
    desiredState: 'Enabled';
    profile: 'gateway-production' | 'gateway-evaluation';
    customerProfile?: string;
    coexistence: {
      enabled: boolean;
      retainInactiveLane: boolean;
    };
  };
  status?: {
    phase?: string;
    activeMode?: DeploymentMode | 'Unknown';
    conditions?: LayerDeploymentCondition[];
    evidenceRef?: string;
    supportBoundary?: string;
  };
};

export type ApplyLayerDeploymentRequest = {
  namespace: string;
  spec: Omit<LayerDeployment['spec'], 'customerProfile'>;
};

const URL_PREFIX = '/project-matrix';
const BFF_API_VERSION = 'v1';

const responseData = <T,>(response: unknown): T => {
  if (isModArchResponse<T>(response)) {
    return response.data;
  }
  throw new Error('Project Matrix returned an invalid response format');
};

export const getGatekeeperDeployment =
  (hostPath: string) =>
  (opts: APIOptions, namespace: string): Promise<LayerDeployment | null> =>
    handleRestFailures(
      restGET(
        hostPath,
        `${URL_PREFIX}/api/${BFF_API_VERSION}/layerdeployments/gatekeeper`,
        { namespace },
        opts,
      ),
    ).then((response) => responseData<LayerDeployment | null>(response));

export const applyGatekeeperDeployment =
  (hostPath: string) =>
  (
    opts: APIOptions,
    request: ApplyLayerDeploymentRequest,
  ): Promise<LayerDeployment> =>
    handleRestFailures(
      restCREATE(
        hostPath,
        `${URL_PREFIX}/api/${BFF_API_VERSION}/layerdeployments/gatekeeper`,
        request as unknown as Record<string, unknown>,
        {},
        opts,
      ),
    ).then((response) => responseData<LayerDeployment>(response));

