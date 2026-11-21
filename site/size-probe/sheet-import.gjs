// <EuiSheet> and the import screen <EuiSheetImport>.
import { EuiSheet, EuiSheetImport } from '@ember-eui/sheet';

console.log(
  <template>
    <EuiSheet @fields={{@fields}} @records={{@records}} />
    <EuiSheetImport @fields={{@fields}} />
  </template>,
);
