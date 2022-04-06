---
order: 1
---

```hbs template
<EuiFieldSearch
  @isClearable={{true}}
  @clear={{set this 'text' ''}}
  @onSearch={{set this 'searchText'}}
  @value={{this.searchText}}
/>
<EuiSpacer />
<EuiTitle>
  Search Text:
  <EuiTextColor @color='success'>
    {{this.searchText}}
  </EuiTextColor>
</EuiTitle>
```

```javascript component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class extends Component {
  @tracked searchText = '';
}
```
