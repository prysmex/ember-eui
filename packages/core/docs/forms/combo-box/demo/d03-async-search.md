---
order: 3
---

# Searching a server

<EuiText>

`@search` replaces the local filtering: it receives the typed text and
returns the matching options, or a promise of them (e.g. a `fetch`). The
combo box shows a loading message until the promise resolves.
`@searchMessage` is shown before the user types.

</EuiText>

```hbs template
<EuiFormRow @label="Assignee">
  <EuiComboBox
    @search={{this.searchUsers}}
    @selectedOptions={{this.selected}}
    @onChange={{this.select}}
    @searchMessage="Type to search users"
    @placeholder="Search users"
    as |user|
  >
    {{user.name}} <EuiTextColor @color="subdued">({{user.email}})</EuiTextColor>
  </EuiComboBox>
</EuiFormRow>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

const USERS = [
  { name: 'Jane Cooper', email: 'jane@example.com' },
  { name: 'Raj Patel', email: 'raj@example.com' },
  { name: 'Li Wei', email: 'li@example.com' },
  { name: 'Ana Souza', email: 'ana@example.com' },
];

export default class AsyncSearchDemo extends Component {
  @tracked selected = [];

  // stands in for `fetch('/api/users?q=' + term).then((r) => r.json())`
  @action
  searchUsers(term) {
    return new Promise((resolve) => {
      setTimeout(() => {
        const query = term.toLowerCase();

        resolve(USERS.filter((user) => user.name.toLowerCase().includes(query)));
      }, 600);
    });
  }

  @action
  select(selected) {
    this.selected = selected;
  }
}
```
