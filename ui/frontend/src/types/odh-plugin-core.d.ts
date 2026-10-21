// Standalone type surface for the Dashboard host extension points.
//
// The real OpenShift AI Dashboard workspace supplies these types when the
// package is host-integrated. Keeping this small declaration local prevents a
// standalone type-check from traversing the host monorepo's source tree and
// loading a second React/csstype graph.
declare module '@odh-dashboard/plugin-core/extension-points' {
  type ComponentCodeRef = () => Promise<unknown>;
  type Extension<Type extends string, Properties> = {
    type: Type;
    properties: Properties;
  };

  type AreaExtension = Extension<'app.area', { id: string; [key: string]: unknown }>;

  type NavItemProperties = {
    id: string;
    title: string;
    section?: string;
    group?: string;
    iconRef?: ComponentCodeRef;
    label?: string;
    dataAttributes?: Record<string, string>;
  };

  type NavExtension =
    | Extension<'app.navigation/section', NavItemProperties>
    | Extension<'app.navigation/href', NavItemProperties & { href: string; path?: string }>;

  type RouteExtension = Extension<
    'app.route',
    { path: string; component: ComponentCodeRef }
  >;
}
