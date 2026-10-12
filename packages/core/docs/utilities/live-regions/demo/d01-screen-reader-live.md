---
order: 1
---

# Announcing a changing count

<EuiText>

Type to filter the list; a screen reader reads the new count, which is
not shown on screen.

</EuiText>

```hbs template
<EuiFieldText
  @placeholder="Filter fruits"
  aria-label="Filter fruits"
  @value={{this.query}}
  {{on "input" this.updateQuery}}
/>
<EuiSpacer @size="s" />
<EuiText @size="s">
  <ul>
    {{#each this.matches as |fruit|}}
      <li>{{fruit}}</li>
    {{/each}}
  </ul>
</EuiText>
<EuiScreenReaderLive>{{this.matches.length}} results</EuiScreenReaderLive>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

const FRUITS = ['Apple', 'Apricot', 'Banana', 'Blueberry', 'Cherry', 'Grape'];

export default class ScreenReaderLiveDemo extends Component {
  @tracked query = '';

  get matches() {
    const query = this.query.toLowerCase();
    return FRUITS.filter((fruit) => fruit.toLowerCase().includes(query));
  }

  @action updateQuery(event) {
    this.query = event.target.value;
  }
}
```
