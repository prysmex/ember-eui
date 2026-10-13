---
order: 2
---

# Delay hide

<EuiText>

<strong>EuiDelayHide</strong> is a component for conditionally toggling the visibility of a child component. It will ensure that the child is visible for at least 1000ms (default). This avoids UI glitches that are common with loading spinners and other elements that are rendered conditionally and potentially for a short amount of time.

</EuiText>

<EuiSpacer />

```hbs template
<EuiFlexItem>
  <EuiFormRow>
    <EuiCheckbox
      @id='delay-hide-checkbox'
      @checked={{this.hide}}
      @label='Hide child'
      {{on 'change' this.onChangeHide}}
    />
  </EuiFormRow>
  <EuiFormRow @label='Minimum duration'>
    <EuiFieldNumber
      @value={{this.minimumDuration}}
      {{on 'input' this.onChangeMinimumDuration}}
    />
  </EuiFormRow>
  <EuiFormRow @label='Child to render'>
    <div>
      <EuiDelayHide @hide={{this.hide}} @minimumDuration={{this.minimumDuration}}>
        <EuiLoadingSpinner @size='m' />
      </EuiDelayHide>
    </div>
  </EuiFormRow>
</EuiFlexItem>
```

```javascript component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class DelayHide extends Component {
  @tracked minimumDuration = 3000;
  @tracked hide = false;

  @action
  onChangeMinimumDuration(event) {
    this.minimumDuration = parseInt(event.target.value, 10);
  }

  @action
  onChangeHide(event) {
    this.hide = event.target.checked;
  }
}
```
