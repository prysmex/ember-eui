---
order: 4
---

# Color options

<EuiText>

Badge colors can be configured with the `@color` argument and the related `@fill` argument. When a named color like `primary` is passed to `@color`, `@fill` determines whether the badge will use filled (more intense) or non-filled (less intense) colors. By default, all badges use non-filled colors.

</EuiText>

```hbs template
<EuiTitle @size="xs"><h2>Accepted color names</h2></EuiTitle>
<EuiSpacer @size="m" />
<EuiFlexGroup @wrap={{true}} @responsive={{false}} @gutterSize="xs">
  {{#each this.badges as |badge|}}
    <EuiFlexItem @grow={{false}}>
      <EuiBadge @color={{badge}}>{{badge}}</EuiBadge>
    </EuiFlexItem>
  {{/each}}
</EuiFlexGroup>
<EuiSpacer />
<EuiTitle @size="xs"><h3>Custom color examples</h3></EuiTitle>
<EuiSpacer @size="m" />
<EuiFlexGroup
  @wrap={{true}}
  @responsive={{false}}
  @gutterSize="xs"
  style="max-width: 300px;"
>
  {{#each this.customBadges as |badge|}}
    <EuiFlexItem @grow={{false}}>
      <EuiBadge @color={{badge}}>{{badge}}</EuiBadge>
    </EuiFlexItem>
  {{/each}}
</EuiFlexGroup>
<EuiSpacer />
<EuiTitle @size="xs"><h3>Disabled state</h3></EuiTitle>
<EuiSpacer @size="m" />
<EuiText @size="s">
  Regardless of the assigned color, all badges use the same disabled state
  styles.
</EuiText>
<EuiSpacer @size="m" />
<EuiSwitch
  @label="Show disabled state"
  @checked={{this.isDisabled}}
  @onChange={{this.setDisabled}}
/>
<EuiSpacer @size="m" />
<EuiFlexGroup @wrap={{true}} @responsive={{false}} @gutterSize="xs">
  <EuiFlexItem @grow={{false}}>
    <EuiBadge @color="success" @isDisabled={{this.isDisabled}}>
      {{if this.isDisabled "Disabled badge" "Disable me!"}}
    </EuiBadge>
  </EuiFlexItem>
</EuiFlexGroup>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class BadgeColorsDemo extends Component {
  badges = ['default', 'hollow', 'primary', 'success', 'accent', 'warning', 'danger'];
  customBadges = ['#DDD', '#AAA', '#666', '#333', '#BADA55', '#FCF7BC', '#FEA27F', '#FFA500', '#0000FF'];

  @tracked isDisabled = false;

  @action
  setDisabled(event) {
    this.isDisabled = event.target.checked;
  }
}
```
