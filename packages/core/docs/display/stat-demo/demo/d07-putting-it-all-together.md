---
order: 7
---

# Putting it all together

<EuiText>
<p>
Following are samples demonstrating how you might assemble and display <strong>EuiStat</strong> components.
</p>
</EuiText>

```hbs template
<div>
  <EuiFlexGroup>
    <EuiFlexItem>
      <EuiPanel>
        <EuiStat
          @title='8,888'
          @description='Total widgets'
          @textAlign='right'
          @isLoading={{this.isLoading}}
        >
          <EuiIcon @type='empty' />
        </EuiStat>
      </EuiPanel>
    </EuiFlexItem>
    <EuiFlexItem>
      <EuiPanel>
        <EuiStat
          @title='2,000'
          @description='Pending widgets'
          @titleColor='accent'
          @textAlign='right'
          @isLoading={{this.isLoading}}
        >
          <EuiIcon @type='clock' @color='accent' />
        </EuiStat>
      </EuiPanel>
    </EuiFlexItem>
    <EuiFlexItem>
      <EuiPanel>
        <EuiStat
          @title='6,800'
          @description='Success widgets'
          @titleColor='success'
          @textAlign='right'
          @isLoading={{this.isLoading}}
        >
          <EuiIcon @type='check' @color='success' />
        </EuiStat>
      </EuiPanel>
    </EuiFlexItem>
    <EuiFlexItem>
      <EuiPanel>
        <EuiStat
          @title='88'
          @description='Error widgets'
          @titleColor='danger'
          @textAlign='right'
          @isLoading={{this.isLoading}}
        >
          <EuiIcon @type='warning' @color='danger' />
        </EuiStat>
      </EuiPanel>
    </EuiFlexItem>
  </EuiFlexGroup>
  <EuiSpacer />
  <EuiSwitch
    @label='Show as loading'
    @checked={{this.isLoading}}
    @onChange={{pick 'target.checked' (set this 'isLoading')}}
  />
</div>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';

export default class StatDemoComponent extends Component {
  @tracked isLoading = false;
}
```
