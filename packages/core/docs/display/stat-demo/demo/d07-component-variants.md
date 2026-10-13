---
order: 7
---

# Component variants

<EuiText>

In the following example, you can see variants of how the **EuiStat** component can be assembled. This component is very helpful for constructing single-value visualizations and summaries for different dashboards and page layouts and for communicating trends over time. Use the `<:description>` named block for markup in the description and the default block for content after the title.

</EuiText>

```hbs template
<div>
  <EuiFlexGroup>
    <EuiFlexItem>
      <EuiPanel @hasBorder={{true}}>
        <EuiFlexGroup>
          <EuiFlexItem>
            <EuiStat
              @title="2,000"
              @textAlign="left"
              @isLoading={{this.isLoading}}
              @titleColor="accent"
            >
              <:description>
                <EuiTextColor @color="accent">
                  <span><EuiIcon @type="clock" @color="accent" /> 70,29%</span>
                </EuiTextColor>
              </:description>
              <:default>Pending widgets</:default>
            </EuiStat>
          </EuiFlexItem>
          <EuiFlexItem>
            <EuiStat
              @title="22,550"
              @textAlign="left"
              @isLoading={{this.isLoading}}
              @titleColor="success"
            >
              <:description>
                <EuiTextColor @color="success">
                  <span><EuiIcon @type="check" @color="success" /> 88,88%</span>
                </EuiTextColor>
              </:description>
              <:default>Successes</:default>
            </EuiStat>
          </EuiFlexItem>
        </EuiFlexGroup>
      </EuiPanel>
    </EuiFlexItem>
    <EuiFlexItem>
      <EuiPanel @hasBorder={{true}}>
        <EuiFlexGroup>
          <EuiFlexItem>
            <EuiStat
              @title="1,554"
              @textAlign="left"
              @isLoading={{this.isLoading}}
              @titleColor="danger"
              @description="Good news"
            >
              <EuiTextColor @color="accent">
                <span><EuiIcon @type="error" @color="danger" /> 66,55%</span>
              </EuiTextColor>
            </EuiStat>
          </EuiFlexItem>
          <EuiFlexItem>
            <EuiStat
              @title="8,888"
              @description="Great news"
              @textAlign="left"
              @isLoading={{this.isLoading}}
            >
              <EuiTextColor @color="success">
                <span><EuiIcon @type="sortUp" /> 27,83%</span>
              </EuiTextColor>
            </EuiStat>
          </EuiFlexItem>
        </EuiFlexGroup>
      </EuiPanel>
    </EuiFlexItem>
  </EuiFlexGroup>
  <EuiSpacer />
  <EuiSwitch
    @label="Show as loading"
    @checked={{this.isLoading}}
    @onChange={{this.onToggleChange}}
  />
</div>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class StatVariantsDemo extends Component {
  @tracked isLoading = false;

  @action
  onToggleChange(event) {
    this.isLoading = event.target.checked;
  }
}
```
