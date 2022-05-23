---
order: 2
---

# Applying color

<EuiText>
<p>
<EuiCode>title</EuiCode> can be altered using the color property. By default, it will appear in <EuiCode>full</EuiCode> color. For proper color contrast, only a limited set of EUI colors are offered. See the Props tab above for a list of available colors.
</p>
</EuiText>

```hbs template
<div>
  <EuiFlexGroup>
    <EuiFlexItem>
      <EuiStat @title='1' @description='Default color' />
    </EuiFlexItem>
    <EuiFlexItem>
      <EuiStat @title='10' @description='Subdued color' @titleColor='subdued' />
    </EuiFlexItem>
    <EuiFlexItem>
      <EuiStat
        @title='100'
        @description='Primary color'
        @titleColor='primary'
      />
    </EuiFlexItem>
    <EuiFlexItem>
      <EuiStat
        @title='1,000'
        @description='Success color'
        @titleColor='success'
      />
    </EuiFlexItem>
    <EuiFlexItem>
      <EuiStat
        @title='10,000'
        @description='Danger color'
        @titleColor='danger'
      />
    </EuiFlexItem>
    <EuiFlexItem>
      <EuiStat
        @title='100,000'
        @description='Accent color'
        @titleColor='accent'
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
