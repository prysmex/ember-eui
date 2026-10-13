---
order: 1
---

# Text diff

<EuiText>

`EuiTextDiff` generates a set of changes between two strings and displays them inline. Pass the strings as `@beforeText` and `@afterText`. Its block yields an array of the identified changes (`[operation, text]`, where the operation is `1` for an insertion, `-1` for a deletion and `0` for unchanged text), here used to count them.

```hbs
<EuiTextDiff @beforeText={{this.beforeText}} @afterText={{this.afterText}} as |diff|>
  {{this.countOf diff 1}} insertions
</EuiTextDiff>
```

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { EuiCode, EuiSpacer, EuiText, EuiTextColor, EuiTextDiff } from '@ember-eui/core/components';

export default class extends Component {
  beforeText =
    'Orbiting this at a distance of roughly ninety-two million miles is an utterly insignificant little blue green planet whose ape- descended life forms are so amazingly primitive that they still think digital watches are a pretty neat idea.';
  afterText =
    'Orbiting those at a distance of roughly ninety-nine billion yards is not insignificant dwarf red green planet whose ape- ascended life forms are so amazingly primitive that they still think digital clocks are a pretty neat idea.';

  countOf = (diff, operation) =>
    diff.filter((chunk) => chunk[0] === operation).length;

  <template>
    <EuiText>
      <p>
        <EuiTextDiff @beforeText={{this.beforeText}} @afterText={{this.afterText}} />
      </p>
    </EuiText>
    <EuiSpacer />
    <EuiTextDiff @beforeText={{this.beforeText}} @afterText={{this.afterText}} as |diff|>
      <EuiCode>
        <EuiTextColor @color='success'> {{this.countOf diff 1}} </EuiTextColor> Insertions,
        <EuiTextColor @color='danger'> {{this.countOf diff -1}} </EuiTextColor>
        Deletions
      </EuiCode>
    </EuiTextDiff>
  </template>
}
```

