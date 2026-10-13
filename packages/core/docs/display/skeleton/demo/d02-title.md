---
order: 2
---

# Title

<EuiText>

Use **EuiSkeletonTitle** to display a placeholder for heading titles.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiFlexGroup, EuiSkeletonTitle, EuiSpacer, EuiSwitch, EuiTitle } from '@ember-eui/core/components';

export default class SkeletonTitleDemo extends Component {
  @tracked isLoading = true;

  titles = [
    { size: 'xxxs', text: 'This is an extra extra extra small title' },
    { size: 'xxs', text: 'This is an extra extra small title' },
    { size: 'xs', text: 'This is an extra small title' },
    { size: 's', text: 'This is a small title' },
    { size: 'm', text: 'This is a medium title' },
    { size: 'l', text: 'This is a large title' },
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
    <EuiFlexGroup @direction="column">
      {{#each this.titles as |title|}}
        <EuiSkeletonTitle
          @size={{title.size}}
          @isLoading={{this.isLoading}}
          @contentAriaLabel="Demo skeleton title"
        >
          <EuiTitle @size={{title.size}}>
            <span>{{title.text}}</span>
          </EuiTitle>
        </EuiSkeletonTitle>
      {{/each}}
    </EuiFlexGroup>
  </template>
}
```

