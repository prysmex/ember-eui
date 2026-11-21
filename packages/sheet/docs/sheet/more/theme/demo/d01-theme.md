---
order: 1
---

# Dark mode and custom colours

<EuiText>

The sheet follows the EUI theme of the nearest `EuiEmotionProvider`:
switch it to dark. The second switch sets two custom properties on the
sheet's own `style` (`--euiSheet-selected`, the range tint, and
`--euiSheet-primary`, the focus and handle colour). Click a few cells to
see them.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { htmlSafe } from '@ember/template';
import {
  EuiEmotionProvider,
  EuiFlexGroup,
  EuiFlexItem,
  EuiPanel,
  EuiSpacer,
  EuiSwitch
} from '@ember-eui/core/components';
import { EuiSheet, localRecords } from '@ember-eui/sheet';
import { inspections, SITES, STATUSES } from 'site/utils/sheet-docs-data';

const FIELDS = [
  { id: 'title', label: 'Inspection', required: true, width: 210 },
  {
    id: 'site',
    label: 'Site',
    type: 'singleSelect',
    options: SITES,
    width: 150
  },
  { id: 'score', label: 'Score', type: 'number', width: 90 },
  {
    id: 'status',
    label: 'Status',
    type: 'singleSelect',
    options: STATUSES,
    width: 110
  },
  { id: 'passed', label: 'Passed', type: 'checkbox', width: 80 }
];

const BRAND = htmlSafe(
  '--euiSheet-selected: rgba(255, 140, 0, 0.18); --euiSheet-primary: #d97706;'
);

export default class SheetTheme extends Component {
  getId = (record) => record.id;
  store = localRecords(inspections(), {
    getRecordId: this.getId,
    fields: FIELDS
  });

  @tracked dark = false;
  @tracked brand = false;

  toggleDark = (event) => (this.dark = event.target.checked);
  toggleBrand = (event) => (this.brand = event.target.checked);

  get style() {
    return this.brand ? BRAND : undefined;
  }

  <template>
    <EuiFlexGroup @gutterSize='m' @responsive={{false}} @wrap={{true}}>
      <EuiFlexItem @grow={{false}}>
        <EuiSwitch
          @label='Dark mode'
          @checked={{this.dark}}
          @onChange={{this.toggleDark}}
          @compressed={{true}}
        />
      </EuiFlexItem>
      <EuiFlexItem @grow={{false}}>
        <EuiSwitch
          @label='Own colours (style)'
          @checked={{this.brand}}
          @onChange={{this.toggleBrand}}
          @compressed={{true}}
        />
      </EuiFlexItem>
    </EuiFlexGroup>
    <EuiSpacer @size='s' />
    <EuiEmotionProvider @colorMode={{if this.dark 'dark' 'light'}}>
      <EuiPanel @paddingSize='s'>
        <EuiSheet
          style={{this.style}}
          @fields={{FIELDS}}
          @records={{this.store.records}}
          @getRecordId={{this.getId}}
          @onChange={{this.store.apply}}
          @height={{260}}
          @ariaLabel='Inspections'
        />
      </EuiPanel>
    </EuiEmotionProvider>
  </template>
}
```
