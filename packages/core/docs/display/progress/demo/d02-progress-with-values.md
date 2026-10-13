---
order: 2
---

# Progress with values

<EuiText>

Once the `@max` and `@value` arguments are set, it will act as a determinate progress bar. This is rendered using an HTML5 `progress` tag.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { registerDestructor } from '@ember/destroyable';
import { EuiButton, EuiFlexGroup, EuiFlexItem, EuiProgress, EuiText } from '@ember-eui/core/components';
import { on } from '@ember/modifier';

export default class ProgressValuesDemo extends Component {
  @tracked value = 0;
  @tracked showProgress = false;
  timer = null;

  constructor(owner, args) {
    super(owner, args);
    registerDestructor(this, () => clearTimeout(this.timer));
  }

  progress(value) {
    if (value > 100) {
      this.value = 100;
    } else {
      this.value = value;
      const diff = Math.round(Math.random() * 10);
      this.timer = setTimeout(() => this.progress(value + diff), 250);
    }
  }

  @action
  toggleProgress() {
    if (!this.showProgress) {
      this.timer = setTimeout(() => this.progress(0), 250);
    } else {
      clearTimeout(this.timer);
      this.value = 0;
    }
    this.showProgress = !this.showProgress;
  }

  <template>
    <EuiFlexGroup @alignItems="center">
      <EuiFlexItem @grow={{false}}>
        <EuiButton @size="s" {{on "click" this.toggleProgress}}>
          Toggle progress
        </EuiButton>
      </EuiFlexItem>
      <EuiFlexItem @grow={{false}}>
        <EuiText>
          <p>{{this.value}}</p>
        </EuiText>
      </EuiFlexItem>
      <EuiFlexItem>
        <EuiProgress @value={{this.value}} @max={{100}} @size="xs" />
      </EuiFlexItem>
    </EuiFlexGroup>
  </template>
}
```

