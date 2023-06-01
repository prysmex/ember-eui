```hbs template
<EuiButton @color='primary' {{on 'click' this.showRandomToast}}>
  Add toast to global toast list
</EuiButton>

<EuiSpacer @size='l' />

<EuiGlobalToastList @toastLifeTimeMs={{3000}} />
```

```js component
import Component from '@glimmer/component';
import { inject as service } from '@ember/service';
import { action } from '@ember/object';
import { guidFor } from '@ember/object/internals';

export default class DemoToastListComponent extends Component {
  @service euiToaster;

  @action
  showRandomToast() {
    this.euiToaster.show({
      onClose: function () {
        console.log('A toast is being closed');
      },
      ...this.toasts[Math.floor(Math.random() * 4)]
    });
  }

  toasts = [
    {
      title: 'You can use markdown for body too!',
      useMarkdownFormat: true,
      body: `
  ##### This tooltip is using markdown!

  You can pass \`useMarkdownFormat: true\`

  [click here](https://www.google.com)

  \`\`\`typescript
    class Hello {
      @tracked count = 1;
    }
  \`\`\`
      `
    },
    {
      title: `Long toast`,
      body: 'This toast overrides the default toastLifeTimeMs value and will be around for 15 seconds.',
      color: 'warning',
      iconType: 'clock',
      toastLifeTimeMs: 15000
    },
    {
      title: `Download complete!`,
      body: 'Thanks for your patience!',
      color: 'success'
    },
    {
      title: `Logging you out soon, due to inactivity`,
      body: 'This is a security measure.',
      color: 'warning',
      iconType: 'user'
    },
    {
      title: `Oops, there was an error`,
      body: 'Sorry. We’ll try not to let it happen it again.',
      color: 'danger',
      iconType: 'help'
    }
  ];
}
```
