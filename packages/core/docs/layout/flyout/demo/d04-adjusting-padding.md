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

{{#if this.flyoutOpen}}
  <EuiFlyout
    @paddingSize={{this.padding}}
    @onClose={{this.closeFlyout}}
  >
    <EuiFlyoutHeader @hasBorder={{true}}>
      <EuiTitle @size='l'>Small Welcome!</EuiTitle>
    </EuiFlyoutHeader>
    <EuiFlyoutBody>
      <:banner>
        <EuiCallOut
          @title='The banner left and right padding is medium to match that of flyout'
        />
      </:banner>

      <:default>
        <TodoText @text="missing EuiButtonGroup component"/>
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
          </EuiFlexItem>
        </EuiFlexGroup>
      </:default>
    </EuiFlyoutBody>
    <EuiFlyoutFooter>
      <EuiFlexGroup @justifyContent='spaceBetween' @gutterSize='s'>
        <EuiButtonEmpty @iconType="cross" {{on 'click' this.closeFlyout}}>
          Close
        </EuiButtonEmpty>
        <EuiButton
          @fill={{true}}
          {{on 'click' this.closeFlyout}}
        >
          Save
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
  @tracked flyoutOpen = false;
  @tracked padding = 'l';

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
    this.flyoutOpen = true;
  }

  @action
  closeFlyout(flyout) {
    this.flyoutOpen = false;
  }
}
```
