---
order: 1
---

# Search on Enter

<EuiText>

By default `@onSearch` runs when the user presses Enter or clears the
field, with the text. Keep the text in `@value` to control it, e.g. to show
the clear button.

</EuiText>

```hbs template
<EuiFieldSearch
  @value={{this.query}}
  @onSearch={{this.search}}
  placeholder="Search and press Enter"
  aria-label="Search"
/>
<EuiSpacer @size="s" />
<EuiText @size="s" @color="subdued">
  <p>Searched for: <strong>{{if this.query this.query "nothing yet"}}</strong></p>
</EuiText>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class SearchDemo extends Component {
  @tracked query = '';

  @action
  search(text) {
    this.query = text;
  }
}
```
