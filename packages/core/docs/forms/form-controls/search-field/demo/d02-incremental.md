---
order: 2
---

# Filter as you type

<EuiText>

With `@incremental={{true}}`, `@onSearch` runs on every keystroke, which
suits filtering a list already on the page.

</EuiText>

```hbs template
<EuiFieldSearch
  @value={{this.query}}
  @onSearch={{this.search}}
  @incremental={{true}}
  placeholder="Filter fruits"
  aria-label="Filter fruits"
/>
<EuiSpacer @size="s" />
<EuiText @size="s">
  <ul>
    {{#each this.matches as |fruit|}}
      <li>{{fruit}}</li>
    {{else}}
      <li>No fruit matches.</li>
    {{/each}}
  </ul>
</EuiText>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

const FRUITS = ['Apple', 'Apricot', 'Banana', 'Blueberry', 'Cherry', 'Grape', 'Mango', 'Orange'];

export default class IncrementalSearchDemo extends Component {
  @tracked query = '';

  get matches() {
    const query = this.query.toLowerCase();

    return FRUITS.filter((fruit) => fruit.toLowerCase().includes(query));
  }

  @action
  search(text) {
    this.query = text;
  }
}
```
