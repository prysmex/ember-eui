---
order: 9
---

# Loading, error and empty states in a page template

<EuiText>

You can then tie multiple types of empty states together to create a seamless loading to empty or loading to error experience. The following example cycles through the states every few seconds inside an `@template="empty"` page template.

</EuiText>

```hbs template
<div style="height: 460px;">
  <EuiPageTemplate @template="empty" @grow={{false}}>
    {{#if (eq this.currentState "error")}}
      <EuiEmptyPrompt
        @color="danger"
        @iconType="error"
        @title="Unable to load your dashboards"
        @body="There was an error loading the Dashboard application. Contact your administrator for help."
      />
    {{else if (eq this.currentState "empty")}}
      <EuiEmptyPrompt
        @color="plain"
        @iconType="dashboardApp"
        @iconColor="default"
        @title="Dashboards"
        @body="You don't have any dashboards yet."
      >
        <:content>
          <EuiTitle @size="m"><h2>Dashboards</h2></EuiTitle>
          <EuiSpacer @size="s" />
          <EuiText @color="subdued"><p>You don't have any dashboards yet.</p></EuiText>
          <EuiSpacer @size="l" />
          <EuiButton @fill={{true}} @iconType="plusCircle">Create new dashboard</EuiButton>
        </:content>
      </EuiEmptyPrompt>
    {{else}}
      <EuiEmptyPrompt @color="subdued" @title="Loading Dashboards">
        <:icon>
          <EuiLoadingLogo @logo="logoKibana" @size="xl" />
        </:icon>
      </EuiEmptyPrompt>
    {{/if}}
  </EuiPageTemplate>
</div>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { registerDestructor } from '@ember/destroyable';

const states = ['loading1', 'error', 'loading2', 'empty'];

export default class EmptyPromptStatesDemo extends Component {
  @tracked currentState = states[0];

  constructor(owner, args) {
    super(owner, args);
    // Cycle through the array of states
    const timer = setInterval(() => {
      const index = states.indexOf(this.currentState);
      this.currentState = states[(index + 1) % states.length];
    }, 3000);
    registerDestructor(this, () => clearInterval(timer));
  }
}
```
