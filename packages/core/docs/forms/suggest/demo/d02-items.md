---
order: 2
---

# Suggestion items

<EuiText>

`EuiSuggestItem` on its own, in the eleven tints. With a description, the
label keeps `@labelWidth` percent of the row (`'fixed'`); without one it
takes what it needs.

</EuiText>

```hbs template
<EuiPanel @paddingSize="none">
  {{#each this.items as |item|}}
    <EuiSuggestItem
      @type={{item.type}}
      @label={{item.label}}
      @description={{item.description}}
      @labelWidth="40"
    />
  {{/each}}
</EuiPanel>
```

```js component
import Component from '@glimmer/component';

const ICONS = ['kqlField', 'kqlValue', 'kqlSelector', 'kqlOperand', 'search', 'clock'];

export default class SuggestItems extends Component {
  items = Array.from({ length: 11 }, (_, i) => ({
    type: { iconType: ICONS[i % ICONS.length], color: `tint${i}` },
    label: `Suggestion in tint${i}`,
    description: i % 2 ? 'With a description' : undefined,
  }));
}
```
