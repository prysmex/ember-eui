---
order: 3
---

# Custom rendering

<EuiText>

The block receives the text to show (truncated or full), like upstream's
render prop, e.g. to highlight a search match inside the visible part.
Pair it with `@truncationPosition` so the match stays visible.

</EuiText>

```hbs template
<div style="width: 260px; max-width: 100%">
  <EuiTextTruncate
    @text={{this.text}}
    @truncation="startEnd"
    @truncationPosition={{this.position}}
    as |text|
  >
    <EuiHighlight @search="needle" @text={{text}} />
  </EuiTextTruncate>
</div>
```

```js component
import Component from '@glimmer/component';

export default class TruncationCustomRendering extends Component {
  text = 'A long haystack of words that hides the needle somewhere after the middle of the string';
  position = this.text.indexOf('needle');
}
```
