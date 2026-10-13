---
order: 1
---

# Catching errors in a component

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { EuiButton, EuiCallOut, EuiSpacer } from '@ember-eui/core/components';

export default class ErrorBoundaryDemo extends Component {
  @tracked error = null;
  @tracked parsed = null;

  @action
  parse() {
    try {
      this.parsed = JSON.parse('{ not json');
      this.error = null;
    } catch (error) {
      this.parsed = null;
      this.error = error;
    }
  }

  @action
  reset() {
    this.error = null;
  }

  <template>
    <div>
      {{#if this.error}}
        <EuiCallOut @title='Something went wrong' @color='danger' @iconType='warning'>
          <p>{{this.error.message}}</p>
          <EuiButton @color='danger' @size='s' {{on 'click' this.reset}}>Dismiss</EuiButton>
        </EuiCallOut>
      {{else}}
        <EuiButton {{on 'click' this.parse}}>Parse invalid JSON</EuiButton>
      {{/if}}
      <EuiSpacer />
    </div>
  </template>
}
```
