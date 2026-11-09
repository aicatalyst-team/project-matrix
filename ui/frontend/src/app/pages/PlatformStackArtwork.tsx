import React from 'react';

export type PlatformLayer = {
  codeName: string;
  name: string;
  available: boolean;
};

type PlatformStackArtworkProps = {
  layers: readonly PlatformLayer[];
  selectedCodeName: string | null;
  onSelect: (codeName: string) => void;
};

type SvgLayerProps = {
  layer: PlatformLayer;
  selected: boolean;
  path: string;
  children: React.ReactNode;
  onSelect: (codeName: string) => void;
};

const ink = '#242424';

const layerFill: Record<string, string> = {
  Loom: '#bfe4f2',
  Bastion: '#ffdf78',
  Gatekeeper: '#b9d88e',
  Bridge: '#b9d88e',
  Flux: '#bfe4f2',
  Ember: '#f45d2e',
  Lens: '#f5a34f',
  Bedrock: '#ef7569',
};

const SvgLayer: React.FC<SvgLayerProps> = ({ layer, selected, path, children, onSelect }) => {
  const activate = () => onSelect(layer.codeName);
  const onKeyDown = (event: React.KeyboardEvent<SVGGElement>) => {
    if (event.key === 'Enter' || event.key === ' ') {
      event.preventDefault();
      activate();
    }
  };

  return (
    <g
      className={'matrix-svg-layer' + (selected ? ' is-selected' : '')}
      role="button"
      tabIndex={0}
      aria-label={layer.name + (layer.available ? ', installer available' : ', coming soon')}
      aria-pressed={selected}
      onClick={activate}
      onKeyDown={onKeyDown}
    >
      <path className="matrix-band-shadow" d={path} fill={ink} />
      <path
        className="matrix-band"
        d={path}
        fill={layerFill[layer.codeName] ?? '#fff'}
        fillOpacity={1}
        style={{ fill: layerFill[layer.codeName] ?? '#fff' }}
      />
      <path className="matrix-band-edge" d={path} />
      <g className="matrix-layer-contents">
        {React.Children.map(children, (child, index) => (
          <g key={`matrix-piece-${index}`} className="matrix-piece" style={{ transitionDelay: `${index * 30}ms` }}>
            {child}
          </g>
        ))}
      </g>
    </g>
  );
};

const BrainIcon = () => (
  <g className="matrix-svg-icon" transform="translate(730 107)">
    <path d="M33 4c-15-8-29 3-25 17-13 7-8 28 7 28 3 15 24 13 27 0 4 12 24 14 28-1 14 0 19-21 7-28C80 6 62-5 49 4c-6-8-12-8-16 0Z" />
    <path d="M39 7v37M25 17c9 0 12 5 12 11M54 12c-8 1-9 8-8 13M54 35c8-2 10-7 9-13M26 39c5-2 9-5 10-10" />
  </g>
);

const HelmIcon = () => (
  <g className="matrix-svg-icon" transform="translate(938 108)">
    <circle cx="38" cy="38" r="23" />
    <circle cx="38" cy="38" r="7" />
    <path d="M38 4v14M38 58v14M4 38h14M58 38h14M14 14l10 10M52 52l10 10M62 14 52 24M24 52 14 62" />
    <path d="M16 48c10-8 34-8 44 0M21 26c11 8 23 8 34 0" />
  </g>
);

const StrandsIcon = () => (
  <g className="matrix-svg-icon" transform="translate(1255 108)">
    <path d="M8 14c26-20 46 20 18 25-26 5-15 31 11 18 17-9 25-30 44-22" />
    <circle cx="9" cy="14" r="5" /><circle cx="78" cy="35" r="5" /><circle cx="37" cy="57" r="5" />
  </g>
);

const GearIcon = () => (
  <g className="matrix-svg-icon" transform="translate(1442 106)">
    <path d="m39 3 7 12 13-1 5 12 12 6-5 12 8 10-9 10 5 12-12 6-2 13-13-1-8 11-12-6-12 6-8-11-13 1-2-13-12-6 5-12-9-10 8-10-5-12 12-6 5-12 13 1 7-12Z" />
    <circle cx="39" cy="39" r="18" />
  </g>
);

const CubeIcon = () => (
  <g className="matrix-svg-icon" transform="translate(825 314)">
    <path d="m38 4 30 17v34L38 72 8 55V21Z" />
    <path d="m8 21 30 18 30-18M38 39v33" />
  </g>
);

const ShieldIcon = () => (
  <g className="matrix-svg-icon matrix-svg-shield" transform="translate(1094 313)">
    <path d="M38 3 68 14v25c0 18-12 29-30 39C20 68 8 57 8 39V14Z" />
    <path d="m21 38 11 11 24-27" />
  </g>
);

const IdentityIcon = () => (
  <g className="matrix-svg-icon" transform="translate(1334 313)">
    <path d="M38 4 68 14v25c0 18-12 29-30 39C20 68 8 57 8 39V14Z" />
    <circle cx="38" cy="31" r="8" />
    <path d="M22 57c6-12 26-12 32 0" />
  </g>
);

const ToolIcon = () => (
  <g className="matrix-svg-icon" transform="translate(1095 902)">
    <path d="M9 11c11-9 26-3 27 9L23 32l17 17-9 9-17-17-12 13c-8-2-12-11-6-18l13-13C6 20 6 15 9 11Z" />
    <path d="m51 8 18 18M57 2l18 18" />
  </g>
);

const ChatIcon = () => (
  <g className="matrix-svg-icon" transform="translate(660 904)">
    <path d="M8 8h47v31H30L17 51V39H8Z" />
    <path d="M34 24h42v28H62l-10 10V52H34Z" />
  </g>
);

const ChipIcon = ({ x, y }: { x: number; y: number }) => (
  <g className="matrix-svg-icon" transform={'translate(' + x + ' ' + y + ')'}>
    <rect x="12" y="12" width="52" height="52" rx="4" />
    <rect x="26" y="26" width="24" height="24" />
    <path d="M12 0v12M25 0v12M38 0v12M51 0v12M64 0v12M12 64v12M25 64v12M38 64v12M51 64v12M64 64v12M0 12h12M0 25h12M0 38h12M0 51h12M64 12h12M64 25h12M64 38h12M64 51h12" />
  </g>
);

const PlatformStackArtwork: React.FC<PlatformStackArtworkProps> = ({ layers, selectedCodeName, onSelect }) => {
  const byCode = (codeName: string) => layers.find((layer) => layer.codeName === codeName) ?? {
    codeName,
    name: codeName,
    available: false,
  };

  return (
    <svg
      className={'matrix-stack-svg' + (selectedCodeName ? ' has-selection' : '')}
      viewBox="0 0 1634 1332"
      role="img"
      aria-labelledby="matrix-stack-title matrix-stack-description"
    >
      <title id="matrix-stack-title">The Red Hat AI Stack</title>
      <desc id="matrix-stack-description">Eight interactive horizontal layers from customer frameworks to infrastructure.</desc>
      <defs>
        <filter id="matrix-lift" x="-3%" y="-10%" width="106%" height="125%">
          <feDropShadow dx="0" dy="12" stdDeviation="9" floodColor="#242424" floodOpacity="0.25" />
        </filter>
      </defs>

      <text className="matrix-svg-title" x="817" y="73" textAnchor="middle">THE PLATFORM STACK</text>

      <SvgLayer layer={byCode('Loom')} selected={selectedCodeName === 'Loom'} path="M78 94 Q77 91 84 91 L1568 92 Q1575 92 1576 98 L1573 264 Q1573 270 1566 270 L84 268 Q78 268 78 261 Z" onSelect={onSelect}>
        <text className="matrix-svg-label" x="108" y="153">Customer chooses</text>
        <text className="matrix-svg-label" x="108" y="207">any framework</text>
        <BrainIcon />
        <text className="matrix-svg-item" x="727" y="235" textAnchor="middle">LangGraph</text>
        <HelmIcon />
        <text className="matrix-svg-item" x="978" y="235" textAnchor="middle">CrewAI</text>
        <text className="matrix-svg-adk" x="1136" y="169" textAnchor="middle">ADK</text>
        <text className="matrix-svg-item" x="1136" y="235" textAnchor="middle">ADK</text>
        <StrandsIcon />
        <text className="matrix-svg-item" x="1300" y="235" textAnchor="middle">Strands</text>
        <GearIcon />
        <text className="matrix-svg-item" x="1502" y="235" textAnchor="middle">Custom</text>
      </SvgLayer>

      <SvgLayer layer={byCode('Bastion')} selected={selectedCodeName === 'Bastion'} path="M79 291 Q77 288 85 288 L1568 289 Q1575 289 1576 295 L1573 420 Q1572 426 1566 426 L84 424 Q78 424 78 418 Z" onSelect={onSelect}>
        <text className="matrix-svg-label" x="110" y="370">Secure Agent Onboarding</text>
        <CubeIcon />
        <text className="matrix-svg-item" x="915" y="370">Sandbox</text>
        <ShieldIcon />
        <text className="matrix-svg-brand" x="1170" y="355">SPIFFE/</text>
        <text className="matrix-svg-brand" x="1170" y="391">SPIRE</text>
        <IdentityIcon />
        <text className="matrix-svg-item" x="1430" y="370">Identity</text>
      </SvgLayer>

      <SvgLayer layer={byCode('Gatekeeper')} selected={selectedCodeName === 'Gatekeeper'} path="M79 451 Q77 448 85 448 L1567 449 Q1575 449 1576 455 L1573 586 Q1572 592 1566 592 L84 590 Q78 590 78 584 Z" onSelect={onSelect}>
        <text className="matrix-svg-label" x="108" y="534">Gateway (optional)</text>
        <text className="matrix-svg-item" x="745" y="500" textAnchor="middle">MaaS</text>
        <text className="matrix-svg-item" x="745" y="545" textAnchor="middle">Gateway</text>
        <text className="matrix-svg-item" x="974" y="500" textAnchor="middle">MCP</text>
        <text className="matrix-svg-item" x="974" y="545" textAnchor="middle">Gateway</text>
        <text className="matrix-svg-item" x="1210" y="500" textAnchor="middle">Inference</text>
        <text className="matrix-svg-item" x="1210" y="545" textAnchor="middle">Gateway</text>
        <text className="matrix-svg-small" x="1455" y="500" textAnchor="middle">Rate limiting, Auth,</text>
        <text className="matrix-svg-small" x="1455" y="538" textAnchor="middle">Routing, Quotas</text>
      </SvgLayer>

      <SvgLayer layer={byCode('Bridge')} selected={selectedCodeName === 'Bridge'} path="M79 606 Q77 603 85 603 L1568 604 Q1575 604 1576 610 L1573 744 Q1572 750 1566 750 L84 748 Q78 748 78 742 Z" onSelect={onSelect}>
        <text className="matrix-svg-label" x="108" y="689">OGX (optional)</text>
        <text className="matrix-svg-small" x="520" y="664" textAnchor="middle">Responses</text>
        <text className="matrix-svg-small" x="520" y="700" textAnchor="middle">API</text>
        <text className="matrix-svg-small" x="742" y="664" textAnchor="middle">Messages</text>
        <text className="matrix-svg-small" x="742" y="700" textAnchor="middle">API (Planned)</text>
        <text className="matrix-svg-small" x="955" y="689" textAnchor="middle">Connectors</text>
        <text className="matrix-svg-small" x="1168" y="689" textAnchor="middle">RAG</text>
        <text className="matrix-svg-small" x="1405" y="664" textAnchor="middle">Multi-provider</text>
        <text className="matrix-svg-small" x="1405" y="700" textAnchor="middle">backend</text>
        <text className="matrix-svg-tiny" x="1323" y="728">AI</text>
        <text className="matrix-svg-tiny matrix-svg-blue" x="1375" y="728">Gemini</text>
        <text className="matrix-svg-tiny" x="1498" y="728">OpenAI x</text>
      </SvgLayer>

      <SvgLayer layer={byCode('Flux')} selected={selectedCodeName === 'Flux'} path="M80 774 Q78 771 86 771 L1566 772 Q1574 772 1575 778 L1572 856 Q1571 862 1565 862 L85 860 Q79 860 79 854 Z" onSelect={onSelect}>
        <path className="matrix-dashed-edge" d="M86 775 L1568 776 L1570 858 L84 856 Z" />
        <text className="matrix-svg-label" x="108" y="830">llm-d (optional)</text>
        <text className="matrix-svg-small" x="840" y="830" textAnchor="middle">disaggregated routing, sits on top of vLLM</text>
      </SvgLayer>

      <SvgLayer layer={byCode('Ember')} selected={selectedCodeName === 'Ember'} path="M79 886 Q77 883 85 883 L1568 884 Q1575 884 1576 890 L1573 1009 Q1572 1015 1566 1015 L84 1013 Q78 1013 78 1007 Z" onSelect={onSelect}>
        <text className="matrix-svg-label" x="108" y="967">vLLM (CORE)</text>
        <text className="matrix-svg-star" x="470" y="975">★</text>
        <rect className="matrix-svg-pill" x="642" y="915" width="430" height="74" rx="14" />
        <ChatIcon />
        <text className="matrix-svg-pill-text" x="820" y="965" textAnchor="middle">Chat Completions</text>
        <rect className="matrix-svg-pill" x="1110" y="915" width="380" height="74" rx="14" />
        <ToolIcon />
        <text className="matrix-svg-pill-text" x="1300" y="965" textAnchor="middle">Tool Calling</text>
      </SvgLayer>

      <SvgLayer layer={byCode('Lens')} selected={selectedCodeName === 'Lens'} path="M79 1039 Q77 1036 85 1036 L1568 1037 Q1575 1037 1576 1043 L1573 1160 Q1572 1166 1566 1166 L84 1164 Q78 1164 78 1158 Z" onSelect={onSelect}>
        <text className="matrix-svg-label" x="108" y="1112">AgentOps</text>
        <text className="matrix-svg-star" x="390" y="1122">★</text>
        <rect className="matrix-svg-small-pill" x="510" y="1064" width="270" height="67" rx="10" />
        <text className="matrix-svg-pill-text" x="645" y="1107" textAnchor="middle">Deep tracing</text>
        <rect className="matrix-svg-small-pill" x="805" y="1064" width="200" height="67" rx="10" />
        <text className="matrix-svg-pill-text" x="905" y="1107" textAnchor="middle">EvalHub</text>
        <rect className="matrix-svg-small-pill" x="1032" y="1064" width="270" height="67" rx="10" />
        <text className="matrix-svg-pill-text" x="1167" y="1107" textAnchor="middle">Cost tracking</text>
        <rect className="matrix-svg-small-pill" x="1328" y="1064" width="205" height="67" rx="10" />
        <text className="matrix-svg-pill-text" x="1430" y="1107" textAnchor="middle">Guardrails</text>
      </SvgLayer>

      <SvgLayer layer={byCode('Bedrock')} selected={selectedCodeName === 'Bedrock'} path="M79 1185 Q77 1182 85 1182 L1568 1183 Q1575 1183 1576 1189 L1573 1298 Q1572 1304 1566 1304 L84 1302 Q78 1302 78 1296 Z" onSelect={onSelect}>
        <text className="matrix-svg-label" x="108" y="1255">Infrastructure</text>
        <g className="matrix-svg-icon matrix-svg-openshift" transform="translate(575 1211)">
          <circle cx="38" cy="38" r="25" />
          <path d="M38 3a35 35 0 1 0 31 51M38 73a35 35 0 0 0 31-51" />
        </g>
        <text className="matrix-svg-item" x="700" y="1260">OpenShift</text>
        <ChipIcon x={904} y={1202} />
        <text className="matrix-svg-item" x="1010" y="1260">GPUs</text>
        <ChipIcon x={1110} y={1202} />
        <text className="matrix-svg-item" x="1215" y="1260">TPUs</text>
        <g className="matrix-svg-hat" transform="translate(1320 1211)">
          <path d="M6 42c8-24 54-31 76-13 10 8 11 28 2 39H10c-7-7-8-17-4-26Z" />
          <path d="M15 29c12-25 43-29 62-13l-10 19c-17-7-34-6-52 4Z" />
        </g>
        <text className="matrix-svg-item" x="1460" y="1260">RHEL AI</text>
      </SvgLayer>
    </svg>
  );
};

export default PlatformStackArtwork;
