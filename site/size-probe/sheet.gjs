// An app that renders only <EuiSheet> (the main entry, one component).
import { EuiSheet } from '@ember-eui/sheet';

console.log(
  <template><EuiSheet @fields={{@fields}} @records={{@records}} /></template>,
);
