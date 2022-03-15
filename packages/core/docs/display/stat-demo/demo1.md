---
order: 1
---
# Demo

```hbs template
<div>
  <EuiFlexGroup>
    <EuiFlexItem>
      <EuiStat
        @title='22,123'
        @description='Default Color'
        @titleColor='default'
        @titleSize='s'
      />
    </EuiFlexItem>
    <EuiFlexItem>
      <EuiStat
        @title='22,123'
        @description='Subdued Color'
        @titleColor='subdued'
        @titleSize='s'
      />
    </EuiFlexItem>
    <EuiFlexItem>
      <EuiStat
        @title='22,123'
        @description='Primary Color'
        @titleColor='primary'
        @titleSize='s'
      />
    </EuiFlexItem>
    <EuiFlexItem>
      <EuiStat
        @title='22,123'
        @description='Success Color'
        @titleColor='success'
        @titleSize='s'
      />
    </EuiFlexItem>
    <EuiFlexItem>
      <EuiStat
        @title='22,123'
        @description='Danger Color'
        @titleColor='danger'
        @titleSize='s'
      />
    </EuiFlexItem>
    <EuiFlexItem>
      <EuiStat
        @title='22,123'
        @description='Accent Color'
        @titleColor='accent'
        @titleSize='s'
      />
    </EuiFlexItem>
  </EuiFlexGroup>
</div>
<EuiSpacer />
<div>
  <EuiFlexGroup>
    <EuiFlexItem>
      <EuiStat @title='7,600 mm' @description='Total people' />
    </EuiFlexItem>
  </EuiFlexGroup>
</div>
<EuiSpacer />
<div>
  <EuiFlexGroup>
    <EuiFlexItem>
      <EuiStat
        @title='22,123'
        @description='Total people'
        @titleColor='primary'
      />
    </EuiFlexItem>
    <EuiFlexItem>
      <EuiStat
        @title='22,123'
        @description='Total people'
        @titleColor='accent'
      />
    </EuiFlexItem>
    <EuiFlexItem>
      <EuiStat
        @title='22,123'
        @description='Total people'
        @titleColor='danger'
      />
    </EuiFlexItem>
  </EuiFlexGroup>
</div>

<EuiSpacer />
<div>
  <EuiFlexGroup>
    <EuiFlexItem>
      <EuiStat
        @title='22,123'
        @description='Total people'
        @isLoading={{this.isLoading}}
        @titleColor='primary'
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
<EuiSpacer />
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
          @isLoading={{this.Loading}}
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
          <EuiIcon @type='alert' @color='danger' />
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
  @tracked isLoading = true;
}
```
