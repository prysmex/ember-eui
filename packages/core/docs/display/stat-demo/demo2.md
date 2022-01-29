# Demo

<EuiTitle>Title size</EuiTitle>
<EuiText>
title uses the <EuiCode>EuiTitle</EuiCode> component and thus uses the same sizing property
values (applied via the titleSize property). Although all EuiTitle sizes are
available, suggested sizes include <EuiCode>'l' | 'm' | 's' | 'xs' | 'xxs' | 'xxxs'</EuiCode>. By
default, the size is set to large <EuiCode>l</EuiCode>. The @description label cannot be
re-sized via component properties.
</EuiText>
<EuiSpacer/>

```hbs template
<div>
  <EuiFlexGroup>
    <EuiFlexItem>
      <EuiStat @title='1,000,000' @description='Large size' @titleSize='l' />
    </EuiFlexItem>
    <EuiFlexItem>
      <EuiStat @title='1,000,000' @description='Medium size' @titleSize='m' />
    </EuiFlexItem>
    <EuiFlexItem>
      <EuiStat @title='1,000,000' @description='Small size' @titleSize='s' />
    </EuiFlexItem>
  </EuiFlexGroup>
  <EuiFlexGroup>
    <EuiFlexItem>
      <EuiStat
        @title='1,000,000'
        @description='Extra small size'
        @titleSize='xs'
      />
    </EuiFlexItem>
    <EuiFlexItem>
      <EuiStat
        @title='1,000,000'
        @description='Extra extra small size'
        @titleSize='xxs'
      />
    </EuiFlexItem>
    <EuiFlexItem>
      <EuiStat
        @title='1,000,000'
        @description='Extra extra extra small size'
        @titleSize='xxxs'
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
