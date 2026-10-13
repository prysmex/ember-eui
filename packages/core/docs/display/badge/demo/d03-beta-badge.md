---
order: 3
---

# Beta badge

<EuiText>

The **EuiBetaBadge** was created specifically to call out modules that are not in GA. Generally the labels used are "Beta" or "Lab". They require an extra `@tooltipContent` to describe the purpose of the badge. You can pass an optional `@title` argument to populate the tooltip title or html title attribute but by default it will use the `@label`.

If you pass in an `@iconType`, only the icon will be used in the badge itself and the label will be applied as the title. Only use an icon when attaching the beta badge to small components. Beta badges can also be made clickable by passing `@href` or `@onClick` as needed.

They can also be used in conjunction with **EuiCard** and **EuiKeyPadMenuItem**.

</EuiText>

```hbs template
<EuiTitle @size="xs"><h3>Colors and types</h3></EuiTitle>
<EuiSpacer @size="m" />
{{#each this.defaultColors as |color|}}
  <div style="display: grid; grid-template-columns: repeat(6, max-content); align-items: flex-start; gap: 1rem; margin-block-end: 1rem;">
    <EuiBetaBadge
      @label="Beta"
      @color={{color}}
      @tooltipContent="This module is not GA. Please help us by reporting any bugs."
    />
    <EuiBetaBadge
      @label="Beta"
      @color={{color}}
      @size="s"
      @tooltipContent="This module is not GA. Please help us by reporting any bugs."
    />
    <EuiBetaBadge @label="Beta" @color={{color}} @iconType="beta" />
    <EuiBetaBadge @label="Tech preview" @color={{color}} @iconType="flask" />
    <EuiBetaBadge @size="s" @label="Beta" @color={{color}} @iconType="beta" />
    <EuiBetaBadge @size="s" @label="Tech preview" @color={{color}} @iconType="flask" />
  </div>
{{/each}}
{{#each this.deprecationColors as |color|}}
  <div style="display: grid; grid-template-columns: repeat(2, max-content); align-items: flex-start; gap: 1rem; margin-block-end: 1rem;">
    <EuiBetaBadge
      @label="Deprecated"
      @color={{color}}
      @tooltipContent="This module is not GA. Please help us by reporting any bugs."
    />
    <EuiBetaBadge
      @label="Deprecated"
      @color={{color}}
      @size="s"
      @tooltipContent="This module is not GA. Please help us by reporting any bugs."
    />
  </div>
{{/each}}
<EuiSpacer />
<EuiTitle @size="xs"><h3>Clickable example</h3></EuiTitle>
<EuiSpacer @size="m" />
<div>
  <EuiBetaBadge
    @label="Beta"
    @href="http://www.elastic.co/subscriptions"
    @target="_blank"
  />
</div>
<EuiSpacer />
<EuiTitle @size="xs"><h3>Placement alongside titles</h3></EuiTitle>
<EuiSpacer @size="m" />
<EuiTitle @size="s">
  <h3>
    New feature &nbsp;
    <EuiBetaBadge
      @label="Beta"
      @size="s"
      @tooltipContent="This module is not GA. Please help us by reporting any bugs."
    />
  </h3>
</EuiTitle>
```

```js component
import Component from '@glimmer/component';

export default class BetaBadgeDemo extends Component {
  defaultColors = ['hollow', 'accent'];
  deprecationColors = ['subdued', 'warning'];
}
```
