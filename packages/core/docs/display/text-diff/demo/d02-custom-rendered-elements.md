---
order: 2
---

# Custom rendered elements

<EuiText>

By default, `EuiTextDiff` wraps deletions with `<del>` and insertions with `<ins>` elements. You can replace these elements with the `@deleteComponent` and `@insertComponent` arguments: an HTML tag name, or a component rendering its block. `@sameComponent` wraps the unchanged text too. For full control, render the yielded changes yourself in the block.

Also, since the diff is plain inline HTML, you can wrap it in any contextual element like `EuiText` or `EuiCodeBlock`.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { EuiCodeBlock, EuiTextDiff } from '@ember-eui/core/components';

export default class extends Component {
  beforeText =
    'Orbiting this at a distance of roughly ninety-two million miles is an utterly insignificant little blue green planet whose ape- descended life forms are so amazingly primitive that they still think digital watches are a pretty neat idea.';
  afterText =
    'Orbiting those at a distance of roughly ninety-nine billion yards is not insignificant dwarf red green planet whose ape- ascended life forms are so amazingly primitive that they still think digital clocks are a pretty neat idea.';

  <template>
    <EuiCodeBlock @fontSize='m' @paddingSize='m'>
      <EuiTextDiff
        @beforeText={{this.beforeText}}
        @afterText={{this.afterText}}
        @insertComponent='strong'
        @deleteComponent='s'
      />
    </EuiCodeBlock>
  </template>
}
```
