---
order: 4
---

# Loading and empty

<EuiText>

`@isLoading` shows a spinner and "Loading options"; with no options,
`@emptyMessage` (or "No options available"); a search matching nothing
says so.

</EuiText>

```hbs template
<EuiFlexGroup>
  <EuiFlexItem>
    <EuiSelectable
      @options={{this.none}}
      @isLoading={{true}}
      @listProps={{hash bordered=true}}
      aria-label="Loading example"
    />
  </EuiFlexItem>
  <EuiFlexItem>
    <EuiSelectable
      @options={{this.none}}
      @emptyMessage="You have no saved searches yet"
      @listProps={{hash bordered=true}}
      aria-label="Empty example"
    />
  </EuiFlexItem>
</EuiFlexGroup>
```

```js component
import Component from '@glimmer/component';

export default class SelectableMessages extends Component {
  none = [];
}
```
