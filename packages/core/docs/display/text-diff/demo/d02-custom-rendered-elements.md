---
order: 2
---

# Custom rendered elements

<EuiText>

By default, `EuiTextDiff` wraps deletions with `<del>` and insertions with `<ins>` elements. To use other elements, render the yielded changes yourself in its block (there are no `deleteComponent` / `insertComponent` arguments).

Also, since the diff is plain inline HTML, you can wrap it in any contextual element like `EuiText` or `EuiCodeBlock`.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { EuiCodeBlock, EuiTextDiff } from '@ember-eui/core/components';
import { get } from '@ember/helper';
import { eq } from 'ember-truth-helpers';

export default class extends Component {
  beforeText =
    'Orbiting this at a distance of roughly ninety-two million miles is an utterly insignificant little blue green planet whose ape- descended life forms are so amazingly primitive that they still think digital watches are a pretty neat idea.';
  afterText =
    'Orbiting those at a distance of roughly ninety-nine billion yards is not insignificant dwarf red green planet whose ape- ascended life forms are so amazingly primitive that they still think digital clocks are a pretty neat idea.';

  <template>
    <EuiTextDiff @beforeText={{this.beforeText}} @afterText={{this.afterText}} as |diff|>
      <EuiCodeBlock @fontSize='m' @paddingSize='m'>{{#each diff as |chunk|}}{{#if (eq (get chunk '0') 1)}}<strong>{{get chunk '1'}}</strong>{{else if (eq (get chunk '0') -1)}}<s>{{get chunk '1'}}</s>{{else}}{{get chunk '1'}}{{/if}}{{/each}}</EuiCodeBlock>
    </EuiTextDiff>
  </template>
}
```

