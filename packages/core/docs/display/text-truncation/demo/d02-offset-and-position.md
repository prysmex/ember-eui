---
order: 2
---

# Offset, position and ellipsis

<EuiText>

`@truncationOffset` (for `'start'` and `'end'`) always keeps that many
characters at the start or end, e.g. a file extension.
`@truncationPosition` (for `'startEnd'`) anchors the visible text on a
character index, e.g. a search match; near either end it falls back to
`'end'` or `'start'` truncation. `@ellipsis` replaces the `…` character.

</EuiText>

```hbs template
<div style="width: 240px; max-width: 100%">
  <EuiTextTruncate
    @text="reports/2026/october/weekly-summary-final-v3.pdf"
    @truncationOffset={{4}}
  />
  <EuiSpacer @size="s" />
  <EuiTextTruncate
    @text="reports/2026/october/weekly-summary-final-v3.pdf"
    @truncation="start"
    @truncationOffset={{8}}
  />
  <EuiSpacer @size="s" />
  <EuiTextTruncate
    @text={{this.text}}
    @truncation="startEnd"
    @truncationPosition={{this.position}}
  />
  <EuiSpacer @size="s" />
  <EuiTextTruncate @text={{this.text}} @ellipsis=" [...] " />
</div>
```

```js component
import Component from '@glimmer/component';

export default class TruncationOffsetAndPosition extends Component {
  text = 'The quick brown fox jumps over the lazy dog while the search term appears somewhere in the middle of this long sentence';
  position = this.text.indexOf('search term');
}
```
