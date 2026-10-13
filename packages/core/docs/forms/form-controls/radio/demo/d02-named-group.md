---
order: 2
---

# Radios sharing a name

<EuiText>

Give every radio of a group the same `@name`, check the selected one with `@checked`, and update your value on `change`.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiRadio, EuiSpacer, EuiText } from '@ember-eui/core/components';
import { eq } from 'ember-truth-helpers';
import { on } from '@ember/modifier';
import { fn } from '@ember/helper';

export default class RadioNamedDemo extends Component {
  plans = [
    { id: 'monthly', label: 'Monthly' },
    { id: 'yearly', label: 'Yearly (2 months free)' },
  ];

  @tracked plan = 'monthly';

  @action
  choose(id) {
    this.plan = id;
  }

  <template>
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
  </template>
}
```
