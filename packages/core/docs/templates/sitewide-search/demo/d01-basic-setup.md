---
order: 1
---

# Search for anything

<EuiText>

Click the field or type: the results open below it. Use the arrow keys
and Enter, or click a result; the chosen one is shown below.

</EuiText>

```hbs template
<EuiSelectableTemplateSitewide
  @options={{this.options}}
  @onChange={{this.choose}}
>
  <:popoverFooter>
    <EuiText @size="xs" @color="subdued">
      <p>Quickly search using <kbd>Ctrl</kbd> + <kbd>/</kbd></p>
    </EuiText>
  </:popoverFooter>
</EuiSelectableTemplateSitewide>
<EuiSpacer />
<EuiText @size="s"><p>Chosen: {{this.chosen}}</p></EuiText>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class SitewideSearch extends Component {
  @tracked chosen = 'nothing yet';

  options = [
    {
      label: 'Dashboards',
      icon: { type: 'dashboardApp' },
      meta: [{ text: 'Analytics', type: 'application' }],
    },
    {
      label: 'Revenue by region',
      icon: { type: 'visBarVertical' },
      avatar: { name: 'Sales' },
      meta: [{ text: 'Visualization' }, { text: 'Sales space' }],
    },
    {
      label: 'Production cluster',
      icon: { type: 'logoCloud' },
      meta: [{ text: 'Deployment', type: 'deployment' }, { text: 'eu-west-1' }],
    },
    {
      label: 'Getting started with EUI',
      icon: { type: 'documentation' },
      meta: [{ text: 'Article', type: 'article' }],
    },
    {
      label: 'Login fails with SSO',
      icon: { type: 'bug' },
      meta: [{ text: 'Case', type: 'case' }, { text: 'Opened today' }],
    },
  ];

  @action
  choose(options) {
    this.chosen = options.find((option) => option.checked === 'on')?.label;
  }
}
```
