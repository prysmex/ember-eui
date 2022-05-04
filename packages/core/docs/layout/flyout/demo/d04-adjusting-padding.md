---
order: 4
---

# Adjusting padding

<EuiSpacer />

<EuiText>
  <p>

All the inner flyout components inherit their padding from the wrapping <strong>EuiFlyout</strong> component. This ensures that all the horizontal edges line up no matter the <EuiCode>paddingSize</EuiCode>. When using the <EuiCode>"none"</EuiCode> size, you will need to accommodate your content with some other way of creating distance to the edges of the flyout.

  </p>
  </EuiText>

```hbs template
<EuiButton {{on 'click' this.openFlyout}}>
  Show flyout to test padding sizes
</EuiButton>

{{#if this.flyout2Open}}
  <EuiFlyout
    @paddingSize={{this.padding}}
    @onClose={{this.closeFlyout}}
  >
    <EuiFlyoutHeader @hasBorder={{true}}>
      <EuiTitle @size='l'>Small Welcome!</EuiTitle>
    </EuiFlyoutHeader>
    <EuiFlyoutBody>
      <EuiFlexGroup>
        <EuiFlexItem>
          {{#each this.paddings as |padding|}}
            <EuiButton
              @color={{if (eq padding.id this.padding) 'primary' 'text'}}
              {{on 'click' (set this 'padding' padding.id)}}
            >
              {{padding.label}}
            </EuiButton>
          {{/each}}

          <EuiButton {{on 'click' this.toggleSide}}>
            change from
            {{this.side}}
          </EuiButton>
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
  @tracked padding = 'l';
  @tracked side = 'right';

  @action
  toggleSide() {
    if (this.side === 'right') {
      this.side = 'left';
    } else {
      this.side = 'right';
    }
  }

  paddings = [
    {
      id: 'none',
      label: 'None'
    },
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
