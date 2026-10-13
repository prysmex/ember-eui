---
order: 3
---

# Circle

<EuiText>

Use **EuiSkeletonCircle** to display a circular preview, mainly for avatars.

</EuiText>

```hbs template
<EuiSwitch
  @label="Toggle loaded state"
  @checked={{this.isLoading}}
  @onChange={{this.toggleLoading}}
/>
<EuiSpacer />
<EuiFlexGroup @responsive={{false}} @gutterSize="s" @alignItems="center">
  {{#each this.avatars as |avatar|}}
    <EuiFlexItem @grow={{false}}>
      <EuiSkeletonCircle
        @size={{avatar.size}}
        @isLoading={{this.isLoading}}
        @contentAriaLabel="Demo skeleton avatar"
      >
        <EuiAvatar @size={{avatar.size}} @name={{avatar.name}} />
      </EuiSkeletonCircle>
    </EuiFlexItem>
  {{/each}}
</EuiFlexGroup>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class SkeletonCircleDemo extends Component {
  @tracked isLoading = true;

  avatars = [
    { size: 's', name: 'Raphael' },
    { size: 'm', name: 'Donatello' },
    { size: 'l', name: 'Leonardo' },
    { size: 'xl', name: 'Michelangelo' },
  ];

  @action
  toggleLoading() {
    this.isLoading = !this.isLoading;
  }
}
```
