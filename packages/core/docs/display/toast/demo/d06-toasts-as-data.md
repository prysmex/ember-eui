---
order: 6
---

# Toast list as data

<EuiText>

As upstream, `EuiGlobalToastList` also takes the toasts as an array: `@toasts`, each with a unique `id`, the args of `EuiToast` (`title`, `text`, `color`, `iconType`, …) and an optional `toastLifeTimeMs`. Without `@toasts` it shows the `euiToaster` service's toasts. The list never changes the array: remove the dismissed toast in `@dismissToast`, which is called when its close button is clicked or its time runs out.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { EuiButton, EuiFlexGroup, EuiFlexItem, EuiGlobalToastList } from '@ember-eui/core/components';

const samples = [
  { title: 'Download complete!', color: 'success', text: 'Thanks for your patience!' },
  { title: 'Logging you out soon, due to inactivity', color: 'warning', iconType: 'user', text: 'This is a security measure.' },
  { title: 'Oops, there was an error', color: 'danger', iconType: 'help', text: 'Sorry. We’ll try not to let it happen it again.' },
  { title: 'Long toast', color: 'warning', iconType: 'clock', toastLifeTimeMs: 15000, text: 'This toast stays for 15 seconds.' }
];

let toastId = 0;

export default class extends Component {
  @tracked toasts = [];

  @action
  addToast() {
    const sample = samples[Math.floor(Math.random() * samples.length)];
    this.toasts = [...this.toasts, { ...sample, id: `toast${toastId++}` }];
  }

  @action
  removeToast(removedToast) {
    this.toasts = this.toasts.filter((toast) => toast.id !== removedToast.id);
  }

  @action
  removeAllToasts() {
    this.toasts = [];
  }

  <template>
    <div style='max-width: 320px'>
      <EuiFlexGroup @gutterSize='s'>
        <EuiFlexItem>
          <EuiButton {{on 'click' this.addToast}}>
            Add toast to global toast list
          </EuiButton>
        </EuiFlexItem>
        <EuiFlexItem>
          <EuiButton @color='danger' {{on 'click' this.removeAllToasts}}>
            Remove all toasts
          </EuiButton>
        </EuiFlexItem>
      </EuiFlexGroup>
      <EuiGlobalToastList
        @toasts={{this.toasts}}
        @dismissToast={{this.removeToast}}
        @toastLifeTimeMs={{6000}}
      />
    </div>
  </template>
}
```
