const { ModuleFederationPlugin } = require('@module-federation/enhanced/webpack');
const packageJson = require('../package.json');
const deps = { ...packageJson.dependencies, ...packageJson.peerDependencies };

const moduleFederationConfig = {
  name: 'projectMatrix',
  filename: 'remoteEntry.js',
  shared: {
    react: { singleton: true, requiredVersion: deps.react },
    'react-dom': { singleton: true, requiredVersion: deps['react-dom'] },
    'react-router': { singleton: true, requiredVersion: deps['react-router'] },
    'react-router-dom': { singleton: true, requiredVersion: deps['react-router-dom'] },
    '@patternfly/react-core': {
      singleton: true,
      requiredVersion: deps['@patternfly/react-core'],
    },
    '@odh-dashboard/plugin-core': {
      singleton: true,
      requiredVersion: '0.0.0',
    },
  },
  exposes: {
    './extensions': './src/odh/extensions',
  },
  runtime: false,
  // The OpenShift AI Dashboard host owns the extension-point types. Generating
  // a second remote declaration bundle would traverse the host workspace and
  // create duplicate React/type dependencies in standalone builds.
  dts: false,
};

module.exports = {
  moduleFederationPlugins: [new ModuleFederationPlugin(moduleFederationConfig)],
};
