---
order: 6
---

# Stat loading

<EuiText>
<p>
If you apply the <EuiCode>isLoading</EuiCode> prop, the title will indicate the loading status by swapping the provided title with two flashing dashes.
</p>
</EuiText>

```hbs template
<div>
  <EuiFlexGroup>
    <EuiFlexItem>
      <EuiStat
        @title='7,600 mm'
        @description='Total People'
        @isLoading={{this.isLoading}}
      />
      <EuiSpacer />
      <EuiSwitch
        @label='Show as loading'
        @checked={{this.isLoading}}
        @onChange={{pick 'target.checked' (set this 'isLoading')}}
      />
    </EuiFlexItem>
  </EuiFlexGroup>
</div>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';

export default class StatDemoComponent extends Component {
  @tracked isLoading = true;
}
```
