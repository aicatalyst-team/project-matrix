import React from 'react';
import type { APIOptions } from 'mod-arch-core';
import './ProjectMatrixPage.css';
import { Alert, Badge, Button, PageSection, Spinner, Switch } from '@patternfly/react-core';
import PlatformStackArtwork from './PlatformStackArtwork';
import {
  applyGatekeeperDeployment,
  DeploymentMode,
  GatewayCapabilityStatus,
  GatewayComponent,
  GatewayDemoUseCase,
  getGatekeeperDeployment,
  LayerDeployment,
  LayerDeploymentCondition,
} from '../api/projectMatrix';

const GATEKEEPER_NAMESPACE = 'matrix-system';

const layerCatalog = [
  { name: 'Customer chooses any framework', codeName: 'Loom', available: false, items: ['LangGraph', 'CrewAI', 'ADK', 'Strands', 'Custom'] },
  { name: 'Secure Agent Onboarding', codeName: 'Bastion', available: false, items: ['Sandbox', 'SPIFFE/SPIRE', 'Identity'] },
  { name: 'Gateway (optional)', codeName: 'Gatekeeper', available: true, items: ['MaaS Gateway', 'MCP Gateway', 'Inference Gateway', 'Rate limiting, Auth, Routing, Quotas'] },
  { name: 'OGX (optional)', codeName: 'Bridge', available: false, items: ['Responses API', 'Messages API (Planned)', 'Connectors', 'RAG', 'Multi-provider backend'] },
  { name: 'llm-d (optional)', codeName: 'Flux', available: false, items: ['Disaggregated routing, sits on top of vLLM'] },
  { name: 'vLLM (CORE)', codeName: 'Ember', available: false, items: ['Chat Completions', 'Tool Calling'] },
  { name: 'AgentOps', codeName: 'Lens', available: false, items: ['Deep tracing', 'EvalHub', 'Cost tracking', 'Guardrails'] },
  { name: 'Infrastructure', codeName: 'Bedrock', available: false, items: ['OpenShift', 'GPUs', 'TPUs', 'RHEL AI'] },
] as const;

const profileForMode = (mode: DeploymentMode): LayerDeployment['spec']['profile'] =>
  mode === 'Preview' ? 'gateway-evaluation' : 'gateway-production';

const modeDescription = (mode: DeploymentMode): string =>
  mode === 'Preview'
    ? 'Use the latest available Gateway capabilities for evaluation. This lane may include Technology Preview or Developer Preview features.'
    : 'Use the Red Hat-supported Gateway baseline. Production is selected by default.';

const terminalPhases = new Set(['Ready', 'Degraded', 'Blocked', 'Disabled']);
const gatewayInstallTargets = [
  'MCP Gateway',
  'MaaS Gateway',
  'Identity policy and authenticated exposure',
  'Gateway validation and conformance evidence',
];

const gatewayDemoUseCases: GatewayDemoUseCase[] = [
  {
    name: 'Authenticated MCP tool federation',
    status: 'Not checked',
    detail: 'Demonstrate initialize, tools/list, and an approved non-destructive tools/call through MCP Gateway.',
    actionLabel: 'Go to MCP catalog',
    actionHref: '/ai-hub/mcp-servers/catalog',
  },
  {
    name: 'Governed model response through MaaS',
    status: 'Validation gate',
    detail: 'Connect an agent workflow to MaaS and show the governed model response as the Gateway-layer round trip.',
  },
  {
    name: 'Policy and exposure troubleshooting',
    status: 'Not checked',
    detail: 'Use the generated evidence to explain identity, TLS, routing, quota, and conformance behavior without hidden assumptions.',
  },
];

const gatewayComponents: Array<Pick<GatewayComponent, 'name' | 'detail'>> = [
  { name: 'MCP Gateway', detail: 'Federates MCP servers through the selected Gateway lane.' },
  { name: 'MaaS Gateway', detail: 'Provides the governed model-response path for the Gateway-layer round trip.' },
  { name: 'Identity and exposure', detail: 'Validates authentication, TLS, listener exposure, and the customer access boundary.' },
  { name: 'Routing, quotas, and conformance', detail: 'Proves request routing, limits, status reporting, and end-to-end behavior.' },
];

const statusLabel = (status: GatewayCapabilityStatus): string => status;

const ProjectMatrixPage: React.FC = () => {
  const [deployment, setDeployment] = React.useState<LayerDeployment | null>(null);
  const [selectedMode, setSelectedMode] = React.useState<DeploymentMode>('Production');
  const [loading, setLoading] = React.useState(true);
  const [applying, setApplying] = React.useState(false);
  const [error, setError] = React.useState<string | null>(null);
  const [selectedLayerCodeName, setSelectedLayerCodeName] = React.useState<string | null>(null);

  const loadDeployment = React.useCallback(async (showLoading = true) => {
    if (showLoading) setLoading(true);
    setError(null);
    try {
      const current = await getGatekeeperDeployment('')({} as APIOptions, GATEKEEPER_NAMESPACE);
      setDeployment(current);
      setSelectedMode(current?.spec.mode ?? 'Production');
    } catch (loadError) {
      setError(loadError instanceof Error ? loadError.message : 'Unable to load Red Hat AI Stack status');
    } finally {
      setLoading(false);
    }
  }, []);

  React.useEffect(() => {
    void loadDeployment(true);
  }, [loadDeployment]);

  const phase = deployment?.status?.phase ?? 'Not deployed';
  const waitingForExecution = Boolean(deployment && !terminalPhases.has(phase));

  React.useEffect(() => {
    if (!waitingForExecution) return undefined;
    const timer = window.setInterval(() => void loadDeployment(false), 2500);
    return () => window.clearInterval(timer);
  }, [loadDeployment, waitingForExecution]);

  const applyMode = async (mode: DeploymentMode) => {
    setSelectedMode(mode);
    setApplying(true);
    setError(null);
    try {
      const result = await applyGatekeeperDeployment('')({} as APIOptions, {
        namespace: GATEKEEPER_NAMESPACE,
        spec: {
          layer: 'Gateway',
          codeName: 'Gatekeeper',
          mode,
          desiredState: 'Enabled',
          profile: profileForMode(mode),
          coexistence: { enabled: true, retainInactiveLane: true },
        },
      });
      setDeployment(result);
    } catch (applyError) {
      setError(applyError instanceof Error ? applyError.message : 'Unable to apply the Gateway layer');
    } finally {
      setApplying(false);
    }
  };

  const activeMode = deployment?.status?.activeMode ?? deployment?.spec.mode;
  const ready = phase === 'Ready';
  const retryable = phase === 'Degraded' || phase === 'Blocked';
  const controlsDisabled = loading || applying || waitingForExecution;
  const actionLabel = applying || waitingForExecution
    ? (deployment?.status?.currentStep ?? 'Starting Gateway') + '…'
    : ready
      ? 'Gateway layer installed'
      : retryable
        ? 'Retry Gateway layer'
        : 'Install Gateway layer';

  const activeLayerCodeName = selectedLayerCodeName ?? 'Gatekeeper';
  const selectedLayer = layerCatalog.find((layer) => layer.codeName === activeLayerCodeName) ?? layerCatalog[2];
  const gatekeeperStatus = loading
    ? 'Loading'
    : applying || waitingForExecution
      ? 'Installing'
      : ready
        ? 'Installed'
        : retryable
          ? 'Needs attention'
          : 'Installer available';
  const statusMessage = loading
    ? 'Reading the current installation state from OpenShift AI.'
    : applying || waitingForExecution
      ? deployment?.status?.currentStep ?? 'Starting the Gateway layer.'
      : ready
        ? 'The selected Gateway lane completed and its validation evidence is available.'
        : retryable
          ? deployment?.status?.currentStep ?? 'The Gateway layer is blocked by a dependency or validation gate.'
          : 'Ready to install the selected Gateway lane.';

  const liveGatewayComponents: GatewayComponent[] = deployment?.status?.components?.length
    ? deployment.status.components
    : gatewayComponents.map((component, index) => ({
      ...component,
      status: applying || waitingForExecution
        ? 'Installing'
        : ready && index === 0
          ? 'Healthy'
          : ready
            ? 'Validation gate'
            : 'Not installed',
    }));

  const liveDemoUseCases: GatewayDemoUseCase[] = deployment?.status?.demoUseCases?.length
    ? deployment.status.demoUseCases
    : gatewayDemoUseCases.map((useCase, index) => ({
      ...useCase,
      status: ready && index === 0 ? 'Not checked' : useCase.status,
    }));

  return (
    <PageSection className="matrix-page">
      <div className="matrix-intro">
        <div>
          <p className="matrix-eyebrow">Red Hat AI Stack</p>
          <p className="matrix-intro-copy">
            Select a layer in the stack to see its one-click installer. The selected layer is
            reported against what is actually installed on this OpenShift AI environment.
          </p>
        </div>
        <span className="matrix-stack-count">{layerCatalog.length} horizontal layers</span>
      </div>

      <div className="matrix-artwork-shell">
        <PlatformStackArtwork
          layers={layerCatalog}
          selectedCodeName={selectedLayerCodeName}
          onSelect={setSelectedLayerCodeName}
        />
        <p className="matrix-artwork-help">
          Hover over a layer to lift it from the page. Select a layer to open its installer.
        </p>
      </div>

      {error && (
        <Alert variant="danger" isInline title="Red Hat AI Stack could not complete the request">
          {error}
        </Alert>
      )}

      <section className="matrix-installer-workflow" aria-labelledby="matrix-selected-layer">
        <div className="matrix-rail-heading">
          <div>
            <p className="matrix-rail-kicker">Selected layer</p>
            <h1 id="matrix-selected-layer">{selectedLayer.name}</h1>
            <p className="matrix-rail-copy">
              {selectedLayer.codeName === 'Gatekeeper'
                ? 'The Gatekeeper installer configures and validates the Gateway layer as one guided operation.'
                : 'This layer is mapped into the Red Hat AI Stack and will receive its own one-click installer when its adapter and validation contract are ready.'}
            </p>
          </div>
          <Badge isRead={selectedLayer.available && !retryable}>
            {selectedLayer.codeName === 'Gatekeeper' ? gatekeeperStatus : 'Coming soon'}
          </Badge>
        </div>

        {selectedLayer.codeName === 'Gatekeeper' ? (
          <>
            <div className="matrix-workflow-body">
              <div className="matrix-install-preview">
                <p className="matrix-workflow-kicker">What this installs</p>
                <ul>
                  {gatewayInstallTargets.map((target) => <li key={target}>{target}</li>)}
                </ul>
                <p className="matrix-safety-note">
                  Production is selected by default. The installer checks the current OpenShift AI baseline first;
                  it never approves or triggers platform upgrades.
                </p>
              </div>
              <div className="matrix-workflow-action">
                <Switch
                  id="project-matrix-preview-capabilities"
                  label="Use Innovation lane"
                  isChecked={selectedMode === 'Preview'}
                  isDisabled={controlsDisabled || ready}
                  onChange={(_event, checked) => setSelectedMode(checked ? 'Preview' : 'Production')}
                />
                <p className="matrix-mode-copy">{modeDescription(selectedMode)}</p>
                <Button
                  variant={retryable ? 'secondary' : 'primary'}
                  isDisabled={controlsDisabled || ready}
                  onClick={() => void applyMode(selectedMode)}
                >
                  {applying || waitingForExecution ? <Spinner size="sm" /> : actionLabel}
                </Button>
              </div>
            </div>
            <div className="matrix-execution" aria-live="polite">
              <div className="matrix-execution-heading">
                <div>
                  <p className="matrix-workflow-kicker">Live installation status</p>
                  <h2>{applying || waitingForExecution ? 'Installing Gateway layer' : 'Gateway layer status'}</h2>
                </div>
                <Badge isRead={ready}>{phase}</Badge>
              </div>
              <p className="matrix-execution-step">
                {applying || waitingForExecution ? <Spinner size="sm" /> : null}
                <strong>{statusMessage}</strong>
              </p>
              <div className="matrix-live-status">
                <span><strong>Lane</strong> {activeMode ?? selectedMode}</span>
                <span><strong>Current step</strong> {deployment?.status?.currentStep ?? 'Ready for the first installation action'}</span>
              </div>
            </div>
            <section className="matrix-layer-components" aria-labelledby="matrix-layer-components-heading">
              <div className="matrix-section-heading">
                <div>
                  <p className="matrix-workflow-kicker">Gateway layer contract</p>
                  <h2 id="matrix-layer-components-heading">Components in this installation</h2>
                </div>
                <span className="matrix-section-note">Statuses follow the selected lane</span>
              </div>
              <div className="matrix-component-grid">
                {liveGatewayComponents.map((component) => (
                  <article className="matrix-component-card" key={component.name}>
                    <div className="matrix-component-card-heading">
                      <h3>{component.name}</h3>
                      <span className={`matrix-status matrix-status-${component.status.toLowerCase().replaceAll(' ', '-')}`}>
                        {statusLabel(component.status)}
                      </span>
                    </div>
                    <p>{component.detail}</p>
                  </article>
                ))}
              </div>
            </section>
            <section className="matrix-demo-use-cases" aria-labelledby="matrix-demo-use-cases-heading">
              <div className="matrix-section-heading">
                <div>
                  <p className="matrix-workflow-kicker">Value at the end of install</p>
                  <h2 id="matrix-demo-use-cases-heading">Demo use cases</h2>
                </div>
                <span className="matrix-section-note">The layer is evaluated through these workflows</span>
              </div>
              <div className="matrix-demo-grid">
                {liveDemoUseCases.map((useCase) => (
                  <article className="matrix-demo-card" key={useCase.name}>
                    <div className="matrix-component-card-heading">
                      <h3>{useCase.name}</h3>
                      <span className={`matrix-status matrix-status-${useCase.status.toLowerCase().replaceAll(' ', '-')}`}>
                        {statusLabel(useCase.status)}
                      </span>
                    </div>
                    <p>{useCase.detail}</p>
                    {useCase.actionHref && useCase.actionLabel && (
                      <a className="matrix-demo-link" href={useCase.actionHref}>{useCase.actionLabel} →</a>
                    )}
                  </article>
                ))}
              </div>
            </section>
            {deployment && (
              <details className="matrix-details">
                <summary>View installation details</summary>
                <dl>
                  <dt>Support boundary</dt>
                  <dd>{deployment.status?.supportBoundary ?? 'Awaiting preflight'}</dd>
                  <dt>Validation evidence</dt>
                  <dd>{deployment.status?.evidenceRef ?? 'Created after execution begins'}</dd>
                </dl>
                {deployment.status?.conditions?.map((condition: LayerDeploymentCondition) => (
                  <p key={condition.type + '-' + (condition.lastTransitionTime ?? '')} className="matrix-condition">
                    <strong>{condition.type}</strong> {condition.message ?? condition.reason ?? condition.status}
                  </p>
                ))}
              </details>
            )}
          </>
        ) : (
          <p className="matrix-coming-soon-copy">Coming soon: the installer for {selectedLayer.name}.</p>
        )}
      </section>
    </PageSection>
  );
};

export default ProjectMatrixPage;

