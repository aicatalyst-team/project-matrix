import type {
  AreaExtension,
  NavExtension,
  RouteExtension,
} from '@odh-dashboard/plugin-core/extension-points';

const PROJECT_MATRIX = 'projectMatrix';

const extensions: (NavExtension | RouteExtension | AreaExtension)[] = [
  {
    type: 'app.area',
    properties: {
      id: PROJECT_MATRIX,
    },
  },
  {
    type: 'app.navigation/section',
    properties: {
      id: 'agentic-platform',
      title: 'Agentic Platform',
      group: '5_agent_management',
      iconRef: () => import('./ProjectMatrixNavIcon'),
    },
  },
  {
    type: 'app.navigation/href',
    properties: {
      id: 'project-matrix',
      title: 'Red Hat AI: Agentic Strategy',
      href: '/project-matrix',
      section: 'agentic-platform',
      path: '/project-matrix/*',
    },
  },
  {
    type: 'app.route',
    properties: {
      path: '/project-matrix/*',
      component: () => import('./ProjectMatrixWrapper'),
    },
  },
];

export default extensions;

