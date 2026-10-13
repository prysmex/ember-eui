---
order: 4
---

# Rectangle

<EuiText>

**EuiSkeletonRectangle** allows you define a large and customizable shape via its `@width`, `@height`, and `@borderRadius` arguments.

</EuiText>

```hbs template
<EuiSwitch
  @label="Toggle loaded state"
  @checked={{this.isLoading}}
  @onChange={{this.toggleLoading}}
/>
<EuiSpacer />
<EuiFlexGroup @responsive={{false}} @wrap={{true}}>
  <EuiFlexItem @grow={{false}}>
    <EuiSkeletonRectangle
      @isLoading={{this.isLoading}}
      @contentAriaLabel="Demo skeleton badge"
      @width="54.16px"
      @height="20px"
      @borderRadius="s"
    >
      <EuiBadge @color="success">Active</EuiBadge>
    </EuiSkeletonRectangle>
  </EuiFlexItem>

  <EuiFlexItem @grow={{false}}>
    <EuiSkeletonRectangle
      @isLoading={{this.isLoading}}
      @contentAriaLabel="Demo skeleton image"
      @width={{100}}
      @height={{100}}
      @borderRadius="none"
    >
      <EuiImage
        @size={{100}}
        @src="https://picsum.photos/300/300"
        @alt="A randomized image"
        style="width: 100px; height: 100px;"
      />
    </EuiSkeletonRectangle>
  </EuiFlexItem>

  <EuiFlexItem @grow={{false}}>
    <EuiSkeletonRectangle
      @isLoading={{this.isLoading}}
      @contentAriaLabel="Demo skeleton card"
      @width={{203}}
      @height={{148}}
      @borderRadius="m"
    >
      <EuiCard
        @icon="logoCloud"
        @title="Elastic Cloud"
        @description="Example card description."
        @onClick={{this.noop}}
      />
    </EuiSkeletonRectangle>
  </EuiFlexItem>
</EuiFlexGroup>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class SkeletonRectangleDemo extends Component {
  @tracked isLoading = true;

  @action
  toggleLoading() {
    this.isLoading = !this.isLoading;
  }

  @action
  noop() {}
}
```
