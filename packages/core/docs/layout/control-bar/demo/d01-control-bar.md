---
order: 1
---

# In a container

<EuiText>

An editor-style bar at the bottom of a container (`@position="absolute"`):
breadcrumbs, a spacer, a status text, and buttons. "Console" is a tab
that opens the content area.

</EuiText>

```hbs template
<div style="position: relative; height: 320px; overflow: hidden; border: 1px solid #d3dae6; border-radius: 6px;">
  <EuiText @size="s" style="padding: 16px;">
    <p>Your document goes here.</p>
  </EuiText>
  <EuiControlBar
    @controls={{this.controls}}
    @position="absolute"
    @showContent={{this.showConsole}}
    @size="s"
  >
    <EuiText @size="s" style="padding: 16px;">
      <pre><code>$ ember test
ok 1 Chrome - Acceptance | index
ok 2 Chrome - Integration | nav
# pass 2</code></pre>
    </EuiText>
  </EuiControlBar>
</div>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';

export default class ControlBarDemo extends Component {
  @tracked showConsole = false;
  @tracked saved = false;

  get controls() {
    return [
      {
        controlType: 'breadcrumbs',
        id: 'path',
        breadcrumbs: [{ text: 'Projects' }, { text: 'Website' }, { text: 'README' }],
      },
      { controlType: 'spacer' },
      { controlType: 'text', id: 'status', text: this.saved ? 'Saved' : 'Unsaved changes' },
      { controlType: 'divider' },
      {
        controlType: 'tab',
        id: 'console',
        label: 'Console',
        onClick: () => (this.showConsole = !this.showConsole),
      },
      {
        controlType: 'button',
        id: 'save',
        label: 'Save',
        color: 'primary',
        onClick: () => (this.saved = true),
      },
    ];
  }
}
```
