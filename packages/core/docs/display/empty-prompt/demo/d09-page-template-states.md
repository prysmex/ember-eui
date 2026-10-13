---
order: 9
---

# Loading, error and empty states in a page template

<EuiText>

You can then tie multiple types of empty states together to create a seamless loading to empty or loading to error experience. The following example shows how to incorporate these states with the page template's [`T.EmptyPrompt`](/docs/core/docs/templates/page-template#empty-pages-or-content).

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { registerDestructor } from '@ember/destroyable';
import { EuiButton, EuiLoadingLogo, EuiPageTemplate } from '@ember-eui/core/components';
import { eq } from 'ember-truth-helpers';

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

  <template>
    {{! A fixed height avoids jumps on the page as the state changes. }}
    <div style="height: 460px;">
      <EuiPageTemplate @grow={{false}} as |T|>
        {{#if (eq this.currentState "error")}}
          <T.EmptyPrompt @color="danger" @iconType="error">
            <:title><h2>Unable to load your dashboards</h2></:title>
            <:default>
              <p>
                There was an error loading the Dashboard application. Contact
                your administrator for help.
              </p>
            </:default>
          </T.EmptyPrompt>
        {{else if (eq this.currentState "empty")}}
          <T.EmptyPrompt @color="plain" @iconType="dashboardApp" @iconColor="default">
            <:title><h2>Dashboards</h2></:title>
            <:default><p>You don't have any dashboards yet.</p></:default>
            <:actions as |Item|>
              <Item><EuiButton @fill={{true}} @iconType="plusCircle">Create new dashboard</EuiButton></Item>
            </:actions>
          </T.EmptyPrompt>
        {{else}}
          <T.EmptyPrompt @color="subdued">
            <:icon><EuiLoadingLogo @logo="logoKibana" @size="xl" /></:icon>
            <:title><h2>Loading Dashboards</h2></:title>
          </T.EmptyPrompt>
        {{/if}}
      </EuiPageTemplate>
    </div>
  </template>
}
```
