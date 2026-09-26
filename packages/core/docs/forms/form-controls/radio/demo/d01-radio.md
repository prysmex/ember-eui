---
order: 1
---

# Radios

<EuiText>

Give every radio of a group the same `@name`, check the selected one with
`@checked`, and update your value on `change`.

</EuiText>

```hbs template
{{#each this.plans as |plan|}}
  <EuiRadio
    @name="plan"
    @label={{plan.label}}
    @checked={{eq this.plan plan.id}}
    {{on "change" (fn this.choose plan.id)}}
  />
{{/each}}
<EuiRadio @name="plan" @label="Enterprise (contact sales)" @disabled={{true}} />
<EuiSpacer />
<EuiText @size="s" @color="subdued"><p>Plan: {{this.plan}}</p></EuiText>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class RadioDemo extends Component {
  plans = [
    { id: 'monthly', label: 'Monthly' },
    { id: 'yearly', label: 'Yearly (2 months free)' },
  ];

  @tracked plan = 'monthly';

  @action
  choose(id) {
    this.plan = id;
  }
}
```
