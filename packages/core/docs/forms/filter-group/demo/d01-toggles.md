---
order: 1
---

# Toggles

<EuiText>

Two joined toggles filter a list: only one can be active at a time, and
clicking the active one again shows everything.

</EuiText>

```hbs template
<EuiFilterGroup>
  <EuiFilterButton
    @withNext={{true}}
    @hasActiveFilters={{eq this.status "open"}}
    @numFilters={{this.openCount}}
    {{on "click" (fn this.toggle "open")}}
  >Open</EuiFilterButton>
  <EuiFilterButton
    @hasActiveFilters={{eq this.status "closed"}}
    @numFilters={{this.closedCount}}
    {{on "click" (fn this.toggle "closed")}}
  >Closed</EuiFilterButton>
</EuiFilterGroup>
<EuiSpacer />
<EuiText @size="s">
  <ul>
    {{#each this.visible as |issue|}}
      <li>{{issue.title}} <EuiBadge>{{issue.status}}</EuiBadge></li>
    {{/each}}
  </ul>
</EuiText>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

const ISSUES = [
  { title: 'Login page is slow', status: 'open' },
  { title: 'Typo in the footer', status: 'closed' },
  { title: 'Export to CSV', status: 'open' },
  { title: 'Dark mode flicker', status: 'closed' },
  { title: 'Session expires too soon', status: 'open' },
];

export default class FilterToggles extends Component {
  @tracked status = null;

  get openCount() {
    return ISSUES.filter((issue) => issue.status === 'open').length;
  }

  get closedCount() {
    return ISSUES.filter((issue) => issue.status === 'closed').length;
  }

  get visible() {
    return this.status
      ? ISSUES.filter((issue) => issue.status === this.status)
      : ISSUES;
  }

  @action
  toggle(status) {
    this.status = this.status === status ? null : status;
  }
}
```
