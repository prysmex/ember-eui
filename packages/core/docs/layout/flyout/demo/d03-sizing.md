---
order: 3
---

# Sizing

<EuiSpacer />

<EuiText>
  <p>

Flyouts come in three predefined <EuiCode>sizes</EuiCode> of <EuiCode>'s' | 'm' | 'l'</EuiCode>, which define the width <strong>relative to the window size</strong> with a minimum width defined in pixels. You can otherwise supply your own fixed width in number or string format.

  </p>
  </EuiText>

```hbs template
<EuiButton {{on 'click' this.openFlyout}}>
  Show flyout to test widths
</EuiButton>

{{#if this.flyoutOpen}}
  <EuiFlyout
    @size={{this.size}}
    @onClose={{this.closeFlyout}}
  >
    <EuiFlyoutHeader @hasBorder={{true}}>
      <EuiTitle @size='l'>Small Welcome!</EuiTitle>
    </EuiFlyoutHeader>
    <EuiFlyoutBody>
      <EuiFlexGroup>
        <EuiFlexItem>
          <TodoText @text="missing EuiButtonGroup component"/>
          {{#each this.sizes as |size|}}
            <EuiButton
              @color={{if (eq size.id this.size) 'primary' 'text'}}
              {{on 'click' (set this 'size' size.id)}}
            >
              {{size.label}}
            </EuiButton>
          {{/each}}
        </EuiFlexItem>
      </EuiFlexGroup>
    </EuiFlyoutBody>
  </EuiFlyout>
{{/if}}
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class DemoFlyoutDemo2Component extends Component {
  @tracked flyoutOpen = false;
  @tracked size = 's';

  sizes = [
    {
      id: 's',
      label: 'Small'
    },
    {
      id: 'm',
      label: 'Medium'
    },
    {
      id: 'l',
      label: 'Large'
    },
    {
      id: '400px',
      label: 'Fixed (400)'
    }
  ];

  @action
  openFlyout() {
    this.flyoutOpen = true;
  }

  @action
  closeFlyout(flyout) {
    this.flyoutOpen = false;
  }
}
```
