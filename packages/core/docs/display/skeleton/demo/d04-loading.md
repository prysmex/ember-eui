---
order: 4
---

# Loading and loaded content

<EuiText>

Each skeleton renders its block once `@isLoading` is `false`. To swap a
custom loading layout, use `EuiSkeletonLoading` with `<:loadingContent>` and
`<:loadedContent>`; put the yielded `role` and `ariaLabel` on the loading
layout's root.

</EuiText>

```hbs template
<EuiSwitch
  @label="Loading"
  @checked={{this.isLoading}}
  @onChange={{this.toggle}}
/>
<EuiSpacer />
<EuiSkeletonTitle @isLoading={{this.isLoading}} @size="s" @contentAriaLabel="Report title">
  <EuiTitle @size="s"><h3>Quarterly report</h3></EuiTitle>
</EuiSkeletonTitle>
<EuiSpacer @size="s" />
<EuiSkeletonText
  @isLoading={{this.isLoading}}
  @lines={{2}}
  @size="s"
  @contentAriaLabel="Report summary"
>
  <EuiText @size="s">
    <p>Revenue grew in every region. Support tickets dropped by a third after
      the new onboarding flow shipped.</p>
  </EuiText>
</EuiSkeletonText>
<EuiSpacer />
<EuiSkeletonLoading @isLoading={{this.isLoading}} @contentAriaLabel="Profile">
  <:loadingContent as |loading|>
    <EuiFlexGroup
      @alignItems="center"
      @responsive={{false}}
      role={{loading.role}}
      aria-label={{loading.ariaLabel}}
    >
      <EuiFlexItem @grow={{false}}><EuiSkeletonCircle @size="l" /></EuiFlexItem>
      <EuiFlexItem><EuiSkeletonText @lines={{2}} /></EuiFlexItem>
    </EuiFlexGroup>
  </:loadingContent>
  <:loadedContent>
    <EuiFlexGroup @alignItems="center" @responsive={{false}}>
      <EuiFlexItem @grow={{false}}><EuiAvatar @name="Ada Lovelace" @size="l" /></EuiFlexItem>
      <EuiFlexItem>
        <EuiText @size="s"><p><strong>Ada Lovelace</strong><br />Analyst</p></EuiText>
      </EuiFlexItem>
    </EuiFlexGroup>
  </:loadedContent>
</EuiSkeletonLoading>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class SkeletonLoadingDemo extends Component {
  @tracked isLoading = true;

  @action
  toggle(event) {
    this.isLoading = event.target.checked;
  }
}
```
