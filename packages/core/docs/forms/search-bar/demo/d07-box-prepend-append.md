---
order: 7
---

# Prepend, append and events on the box

<EuiText>

The search field (`@box`) takes upstream's `prepend` and `append`: text becomes the label of an **EuiFormPrepend** / **EuiFormAppend**, and a component renders as is inside the slot (use **EuiFormPrepend**, **EuiFormAppend** or a button inside it). `onClick`, `onFocus` and `onBlur` are called with the event from the field. The focus callback runs next to the hint, which still opens on focus.

</EuiText>

<EuiSpacer />

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiFormAppend, EuiSearchBar, EuiSpacer, EuiText } from '@ember-eui/core/components';

const Scope = <template><EuiFormAppend @iconRight="arrowDown" @label="All" /></template>;

export default class SearchBarBoxDemo extends Component {
  @tracked events = [];

  @action
  log(name) {
    this.events = [...this.events.slice(-4), name];
  }

  get box() {
    return {
      placeholder: 'Search',
      prepend: 'Find',
      append: Scope,
      onClick: () => this.log('click'),
      onFocus: () => this.log('focus'),
      onBlur: () => this.log('blur'),
    };
  }

  <template>
    <EuiSearchBar @box={{this.box}} />
    <EuiSpacer />
    <EuiText @size="s"><p>Last events: {{this.events}}</p></EuiText>
  </template>
}
```
