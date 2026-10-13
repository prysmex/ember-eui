---
order: 3
---

# Circle

<EuiText>

Use **EuiSkeletonCircle** to display a circular preview, mainly for avatars.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiAvatar, EuiFlexGroup, EuiFlexItem, EuiSkeletonCircle, EuiSpacer, EuiSwitch } from '@ember-eui/core/components';

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

  <template>
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
  </template>
}
```

