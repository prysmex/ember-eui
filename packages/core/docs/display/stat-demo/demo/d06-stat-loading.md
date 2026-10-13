---
order: 6
---

# Stat loading

<EuiText>

If you apply the `@isLoading` argument, the title will indicate the loading status by swapping the provided title with two flashing dashes.

</EuiText>

```hbs template
<div>
  <EuiStat @title="7,600 mm" @description="Total People" @isLoading={{this.isLoading}} />
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

export default class StatLoadingDemo extends Component {
  @tracked isLoading = true;

  @action
  onToggleChange(event) {
    this.isLoading = event.target.checked;
  }
}
```
