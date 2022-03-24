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

{{#if this.flyout2Open}}
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
    <EuiFlyoutFooter>
      <EuiFlexGroup @justifyContent='spaceBetween' @gutterSize='s'>
        <EuiButton {{on 'click' (fn this.closeFlyout 'flyout2Open')}}>
          Cancel
        </EuiButton>
        <EuiButton
          @fill={{true}}
          {{on 'click' (fn this.closeFlyout 'flyout2Open')}}
        >
          Send
        </EuiButton>
      </EuiFlexGroup>
    </EuiFlyoutFooter>
  </EuiFlyout>
{{/if}}
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class DemoFlyoutDemo2Component extends Component {
  @tracked flyout2Open = false;
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
    this.flyout2Open = true;
  }

  @action
  closeFlyout(flyout) {
    this.flyout2Open = false;
  }
}
```
