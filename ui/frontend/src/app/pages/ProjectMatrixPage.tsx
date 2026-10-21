import React from 'react';
import type { APIOptions } from 'mod-arch-core';
import {
  Alert,
  Badge,
  Button,
  Card,
  CardBody,
  CardTitle,
  DescriptionList,
  DescriptionListDescription,
  DescriptionListGroup,
  DescriptionListTerm,
  PageSection,
  Spinner,
  Stack,
  StackItem,
  Switch,
  Title,
} from '@patternfly/react-core';
import {
  applyGatekeeperDeployment,
  DeploymentMode,
  getGatekeeperDeployment,
  LayerDeployment,
  LayerDeploymentCondition,
} from '../api/projectMatrix';

const GATEKEEPER_NAMESPACE = 'matrix-system';

const profileForMode = (mode: DeploymentMode): LayerDeployment['spec']['profile'] =>
  mode === 'Preview' ? 'gateway-evaluation' : 'gateway-production';

const modeDescription = (mode: DeploymentMode): string =>
  mode === 'Preview'
    ? 'The Blue Path: an isolated innovation and technology-preview evaluation lane; the Red Hat-managed baseline is retained.'
    : 'The Red Path: supported production capabilities and the production support boundary.';

const terminalPhases = new Set(['Ready', 'Degraded', 'Blocked', 'Disabled']);

const ProjectMatrixPage: React.FC = () => {
  const [deployment, setDeployment] = React.useState<LayerDeployment | null>(null);
  const [selectedMode, setSelectedMode] = React.useState<DeploymentMode>('Production');
  const [loading, setLoading] = React.useState(true);
  const [applying, setApplying] = React.useState(false);
  const [error, setError] = React.useState<string | null>(null);

  const loadDeployment = React.useCallback(async (showLoading = true) => {
    if (showLoading) {
      setLoading(true);
    }
    setError(null);
    try {
      const current = await getGatekeeperDeployment('')({} as APIOptions, GATEKEEPER_NAMESPACE);
      setDeployment(current);
      setSelectedMode(current?.spec.mode ?? 'Production');
    } catch (loadError) {
      setError(loadError instanceof Error ? loadError.message : 'Unable to load Project Matrix status');
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
    if (!waitingForExecution) {
      return undefined;
    }
    const timer = window.setInterval(() => {
      void loadDeployment(false);
    }, 2500);
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
          coexistence: {
            enabled: true,
            retainInactiveLane: true,
          },
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

  return (
    <PageSection>
      <Stack hasGutter>
        <StackItem>
          <Title headingLevel="h1">Project Matrix · The Construct</Title>
          <p>
            Red Hat AI: Agentic Strategy turns the horizontal platform stack into opinionated,
            production-ready layers. Start with Gateway: The Gatekeeper.
          </p>
        </StackItem>

        {error && (
          <StackItem>
            <Alert variant="danger" isInline title="Project Matrix could not complete the request">
              {error}
            </Alert>
          </StackItem>
        )}

        <StackItem>
          <Card>
            <CardTitle>Gateway · The Gatekeeper</CardTitle>
            <CardBody>
              <p>
                A single opinionated entry point for MCP Gateway, MaaS Gateway, approved identity
                policy, and the layer&apos;s Aramock-derived evaluation evidence.
              </p>
              <Switch
                id="project-matrix-preview-capabilities"
                label={`Innovation lane · The Blue Path (${selectedMode === 'Preview' ? 'ON' : 'OFF'})`}
                isChecked={selectedMode === 'Preview'}
                isDisabled={controlsDisabled}
                onChange={(_event, checked) => void applyMode(checked ? 'Preview' : 'Production')}
              />
              <p>
                {modeDescription(selectedMode)} The same OpenShift AI instance is used when the
                dependency and ownership checks permit coexistence.
              </p>
              <p>
                This click evaluates the current OpenShift AI baseline first. Platform-owned
                upgrades are never approved or triggered here; after an upgrade, the layer must
                be revalidated against its recorded compatibility baseline.
              </p>
              {!deployment && !loading && (
                <Button
                  variant="primary"
                  isDisabled={applying}
                  onClick={() => void applyMode(selectedMode)}
                >
                  {applying ? <Spinner size="sm" /> : 'Deploy Gateway · The Gatekeeper'}
                </Button>
              )}
              {retryable && (
                <Button
                  variant="secondary"
                  isDisabled={applying}
                  onClick={() => void applyMode(selectedMode)}
                >
                  Retry Gateway · The Gatekeeper deployment
                </Button>
              )}
              {applying && deployment && <Spinner size="md" aria-label="Applying Gateway layer" />}
            </CardBody>
          </Card>
        </StackItem>

        <StackItem>
          <Card>
            <CardTitle>Deployment status</CardTitle>
            <CardBody>
              {loading ? (
                <Spinner aria-label="Loading Project Matrix status" />
              ) : (
                <DescriptionList isHorizontal aria-live="polite">
                  <DescriptionListGroup>
                    <DescriptionListTerm>Phase</DescriptionListTerm>
                    <DescriptionListDescription>
                      <Badge isRead={ready}>{phase}</Badge>
                    </DescriptionListDescription>
                  </DescriptionListGroup>
                  <DescriptionListGroup>
                    <DescriptionListTerm>Requested mode</DescriptionListTerm>
                    <DescriptionListDescription>{selectedMode}</DescriptionListDescription>
                  </DescriptionListGroup>
                  <DescriptionListGroup>
                    <DescriptionListTerm>Active mode</DescriptionListTerm>
                    <DescriptionListDescription>{activeMode ?? '—'}</DescriptionListDescription>
                  </DescriptionListGroup>
                  <DescriptionListGroup>
                    <DescriptionListTerm>Support boundary</DescriptionListTerm>
                    <DescriptionListDescription>
                      {deployment?.status?.supportBoundary ?? 'Awaiting preflight'}
                    </DescriptionListDescription>
                  </DescriptionListGroup>
                  <DescriptionListGroup>
                    <DescriptionListTerm>Evidence</DescriptionListTerm>
                    <DescriptionListDescription>
                      {deployment?.status?.evidenceRef ?? 'Created after execution begins'}
                    </DescriptionListDescription>
                  </DescriptionListGroup>
                </DescriptionList>
              )}
            </CardBody>
          </Card>
        </StackItem>

        {deployment?.status?.conditions?.map((condition: LayerDeploymentCondition) => (
          <StackItem key={`${condition.type}-${condition.lastTransitionTime ?? ''}`}>
            <Alert
              variant={condition.status === 'False' ? 'warning' : 'info'}
              isInline
              title={condition.type}
            >
              {condition.message ?? condition.reason ?? condition.status}
            </Alert>
          </StackItem>
        ))}
      </Stack>
    </PageSection>
  );
};

export default ProjectMatrixPage;

