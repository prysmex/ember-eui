---
order: 3
---

# Nested panels

<EuiText>

`EuiContextMenu` shows one panel at a time. "Share" opens its panel, and
"Edit" a panel with a form rendered by the `<:content>` block. Try the
arrow keys: up and down move between items, right opens a panel, left
goes back.

</EuiText>

```hbs template
<EuiPopover
  @isOpen={{this.isOpen}}
  @closePopover={{this.close}}
  @panelPaddingSize="none"
  @anchorPosition="downLeft"
>
  <:button>
    <EuiButton @iconType="arrowDown" @iconSide="right" {{on "click" this.toggle}}>
      Actions
    </EuiButton>
  </:button>
  <:content>
    <EuiContextMenu @panels={{this.panels}} @initialPanelId="main">
      <:content as |panel|>
        {{#if (eq panel.id "rename")}}
          <div style="padding: 16px;">
            <EuiFormRow @label="Name">
              <EuiFieldText @value={{this.name}} @compressed={{true}} {{on "input" this.setName}} />
            </EuiFormRow>
            <EuiSpacer @size="s" />
            <EuiButton @size="s" @fill={{true}} {{on "click" this.close}}>Save</EuiButton>
          </div>
        {{/if}}
      </:content>
    </EuiContextMenu>
  </:content>
</EuiPopover>
<EuiSpacer />
<EuiText @size="s"><p>Last action: {{this.lastAction}}</p></EuiText>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class NestedPanels extends Component {
  @tracked isOpen = false;
  @tracked name = 'Quarterly report';
  @tracked lastAction = 'none';

  get panels() {
    const run = (name) => () => {
      this.lastAction = name;
      this.isOpen = false;
    };

    return [
      {
        id: 'main',
        title: 'Actions',
        items: [
          { name: 'Edit', icon: 'pencil', panel: 'rename' },
          { name: 'Share', icon: 'share', panel: 'share' },
          { name: 'Duplicate', icon: 'copy', onClick: run('Duplicate') },
          { isSeparator: true },
          { name: 'Delete', icon: 'trash', onClick: run('Delete') },
        ],
      },
      {
        id: 'share',
        title: 'Share',
        items: [
          { name: 'Copy link', icon: 'link', onClick: run('Copy link') },
          { name: 'Email', icon: 'email', onClick: run('Email') },
          { name: 'Embed', icon: 'console', panel: 'embed' },
        ],
      },
      {
        id: 'embed',
        title: 'Embed',
        items: [
          { name: 'As an iframe', onClick: run('Embed as an iframe') },
          { name: 'As an image', onClick: run('Embed as an image') },
        ],
      },
      { id: 'rename', title: 'Edit', width: 300 },
    ];
  }

  @action
  toggle() {
    this.isOpen = !this.isOpen;
  }

  @action
  close() {
    this.isOpen = false;
  }

  @action
  setName(event) {
    this.name = event.target.value;
  }
}
```
