---
order: 2
---

# Toast list

<EuiText>

Each click shows a random toast through the `euiToaster` service. A toast's `body` is text, or a component for rich content (the service cannot pass blocks), as most of the toasts below show; `EuiGlobalToastList` renders them and dismisses each after `@toastLifeTimeMs`, unless the toast sets its own `toastLifeTimeMs`.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { service } from '@ember/service';
import { action } from '@ember/object';
import { EuiButton, EuiCode, EuiFlexGroup, EuiFlexItem, EuiGlobalToastList } from '@ember-eui/core/components';
import { on } from '@ember/modifier';

const LongBody = <template>
  <p>
    Here’s some stuff that you need to know. We can make this text really long so that, when viewed within a browser
    that’s fairly narrow, it will wrap, too.
  </p>
  <p>And some other stuff on another line, just for kicks. And <a href='#'>here’s a link</a>.</p>
</template>;

const DownloadBody = <template><p>Thanks for your patience!</p></template>;

const InactivityBody = <template>
  <p>This is a security measure.</p>
  <p>Please move your mouse to show that you’re still using Kibana.</p>
</template>;

const ErrorBody = <template><p>Sorry. We’ll try not to let it happen it again.</p></template>;

const LongToastBody = <template>
  <p>
    This toast overrides the default <EuiCode>toastLifeTimeMs</EuiCode> value and will be around for 15 seconds.
  </p>
</template>;

const toasts = [
  {
    title: "Check it out, here's a really long title that will wrap within a narrower browser",
    body: LongBody,
  },
  {
    title: 'Download complete!',
    color: 'success',
    body: DownloadBody,
  },
  {
    title: 'Logging you out soon, due to inactivity',
    color: 'warning',
    iconType: 'user',
    body: InactivityBody,
  },
  {
    title: 'Oops, there was an error',
    color: 'danger',
    iconType: 'help',
    body: ErrorBody,
  },
  {
    title: 'Long toast',
    color: 'warning',
    iconType: 'clock',
    toastLifeTimeMs: 15000,
    body: LongToastBody,
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
      <EuiGlobalToastList @toastLifeTimeMs={{6000}} />
    </div>
  </template>
}
```

