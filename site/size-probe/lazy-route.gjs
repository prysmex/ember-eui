// An app shell with a button, and a route (here: a dynamic import) that
// renders a data grid. Only the shell should be in the static graph.
import EuiButton from '@ember-eui/core/components/eui-button';

console.log(
  <template>
    <EuiButton>Open</EuiButton>
  </template>,
  () => import('@ember-eui/core/components/eui-data-grid'),
);
