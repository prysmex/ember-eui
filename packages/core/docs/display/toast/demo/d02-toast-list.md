---
order: 2
---

# Toast list

<EuiText>

Each click shows a random toast through the `euiToaster` service; `EuiGlobalToastList` renders them and dismisses each after `@toastLifeTimeMs`, unless the toast sets its own `toastLifeTimeMs`.

</EuiText>

```hbs template
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
  <EuiGlobalToastList @toastLifeTimeMs={{6000}} />
</div>
```

```js component
import Component from '@glimmer/component';
import { service } from '@ember/service';
import { action } from '@ember/object';

const toasts = [
  {
    title: "Check it out, here's a really long title that will wrap within a narrower browser",
    useMarkdownFormat: true,
    body: `Here’s some stuff that you need to know. We can make this text really long so that, when viewed within a browser that’s fairly narrow, it will wrap, too.

And some other stuff on another line, just for kicks. And [here’s a link](#).`,
  },
  {
    title: 'Download complete!',
    color: 'success',
    body: 'Thanks for your patience!',
  },
  {
    title: 'Logging you out soon, due to inactivity',
    color: 'warning',
    iconType: 'user',
    body: 'This is a security measure. Please move your mouse to show that you’re still using Kibana.',
  },
  {
    title: 'Oops, there was an error',
    color: 'danger',
    iconType: 'help',
    body: 'Sorry. We’ll try not to let it happen it again.',
  },
  {
    title: 'Long toast',
    color: 'warning',
    iconType: 'clock',
    toastLifeTimeMs: 15000,
    body: 'This toast overrides the default toastLifeTimeMs value and will be around for 15 seconds.',
  },
];

export default class extends Component {
  @service euiToaster;

  @action
  addToast() {
    this.euiToaster.show({
      ...toasts[Math.floor(Math.random() * toasts.length)],
    });
  }

  @action
  removeAllToasts() {
    this.euiToaster.toasts = [];
  }
}
```
