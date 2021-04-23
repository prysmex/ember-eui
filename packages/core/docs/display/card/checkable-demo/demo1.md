# Demo

```hbs template
<EuiFlexGroup @wrap={{true}} @alignItems="flexStart">
  <div style="min-width: 400px;" class="euiFlexItem">
    <EuiCheckableCard
      @label="Radio 1"
    />
  </div>
  <div style="min-width: 400px;" class="euiFlexItem">
    <EuiCheckableCard
      @label="Radio 1 (Selected)"
      @checked={{true}}
    />
  </div>
  <div style="min-width: 400px;" class="euiFlexItem">
    <EuiCheckableCard
      @label="Radio 1 (Disabled)"
      @disabled={{true}}
    />
  </div>
  <div style="min-width: 400px;" class="euiFlexItem">
    <EuiCheckableCard
      @checkableType="checkbox"
      @label="Click on this checkbox"
    />
  </div>
  <div style="min-width: 400px;" class="euiFlexItem">
    <EuiCheckableCard
      @checkableType="checkbox"
      @label="Click on this checkbox (Selected)"
      @checked={{true}}
    />
  </div>
  <div style="min-width: 400px;" class="euiFlexItem">
    <EuiCheckableCard
      @checkableType="checkbox"
      @label="Click on this checkbox (Disabled)"
      @disabled={{true}}
    />
  </div>
  <div style="min-width: 400px;" class="euiFlexItem">
    <EuiCheckableCard
      @iconClasses="pl-2"
      @checkableType="checkbox"
    >
      <:label>
        <EuiIcon @type="logoGolang" @size="l" />
        Click on this checkbox
      </:label>
    </EuiCheckableCard>
  </div>
  <div style="min-width: 400px;" class="euiFlexItem">
    <EuiCheckableCard
      @iconClasses="pl-2"
      @checkableType="checkbox"
      @label="This is a checkable card with more content inside"
    >
      <:content>
        <EuiRadioGroup
          @options={{this.radios}}
          @idSelected={{this.selectedRadioId}}
          @onChange={{set this "selectedRadioId"}}
        />
      </:content>
    </EuiCheckableCard>
  </div>
</EuiFlexGroup>
```

```javascript component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class DemoCheckableCardomponent extends Component {
  radios = [
    {
      id: 'radio-1',
      label: 'radio 1',
    },
    {
      id: 'radio-2',
      label: 'radio 2',
    },
    {
      id: 'radio-3',
      label: 'radio 3',
    },
    {
      id: 'radio-4',
      label: 'radio 4',
    },
  ];

  @tracked selectedRadioId = null;
}
```
