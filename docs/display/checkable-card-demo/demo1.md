# Demo

```hbs template
<div class="euiFlexGrid euiFlexGrid--halves euiFlexGrid--responsive euiFlexGrid--gutterLarge">
  <div class="euiFlexItem">
    <EuiCheckableCard
      @label="Radio 1"
    />
  </div>
  <div class="euiFlexItem">
    <EuiCheckableCard
      @label="Radio 1 (Selected)"
      @checked={{true}}
    />
  </div>
  <div class="euiFlexItem">
    <EuiCheckableCard
      @label="Radio 1 (Disabled)"
      @disabled={{true}}
    />
  </div>
  <div class="euiFlexItem">
    <EuiCheckableCard
      @checkableType="checkbox"
      @label="Click on this checkbox"
    />
  </div>
  <div class="euiFlexItem">
    <EuiCheckableCard
      @checkableType="checkbox"
      @label="Click on this checkbox (Selected)"
      @checked={{true}}
    />
  </div>
  <div class="euiFlexItem">
    <EuiCheckableCard
      @checkableType="checkbox"
      @label="Click on this checkbox (Disabled)"
      @disabled={{true}}
    />
  </div>
  <div class="euiFlexItem">
    <EuiCheckableCard
      @iconClasses="pl-2"
      @checkableType="checkbox"
      @label="Click on this checkbox"
    >
      <:icon>
        <div class="euiFlexGroup euiFlexGroup--directionColumn euiFlexGroup--justifyContentSpaceAround">
          <EuiIcon @type="logoGolang" @size="l" />
        </div>
      </:icon>
    </EuiCheckableCard>
  </div>
  <div class="euiFlexItem">
    <EuiCheckableCard
      @iconClasses="pl-2"
      @checkableType="checkbox"
    >
      <:icon>
        <div class="euiFlexGroup euiFlexGroup--directionColumn euiFlexGroup--justifyContentSpaceAround">
          <EuiIcon @type="logoGolang" @size="l" />
        </div>
      </:icon>
      <:label>
        This is a header checkbox label
      </:label>
    </EuiCheckableCard>
  </div>
  <div class="euiFlexItem">
    <EuiCheckableCard
      @iconClasses="pl-2"
      @checkableType="checkbox"
    >
      <:icon>
        <div class="euiFlexGroup euiFlexGroup--directionColumn euiFlexGroup--justifyContentSpaceAround">
          <EuiIcon @type="logoGolang" @size="l" />
        </div>
      </:icon>
      <:label>
        <div class="euiFlexGroup euiFlexGroup--directionColumn">
          <EuiText>
            This is a checkable card with more content inside
          </EuiText>
          <EuiRadioGroup
            @options={{this.radios}}
            @idSelected={{this.selectedRadioId}}
            @onChange={{set this.selectedRadioId}}
          />
        </div>
      </:label>
    </EuiCheckableCard>
  </div>
</div>
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
