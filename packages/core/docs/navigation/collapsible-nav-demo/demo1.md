---
order: 1
---
# Collapsible nav

```hbs template
<EuiTitle @size='s'>
  Collapsible Nav
</EuiTitle>
<EuiCollapsibleNav
  @isOpen={{this.collNavIsOpen}}
  @onClose={{this.closeCollapsibleNav}}
  @showCloseButton={{true}}
  @size={{240}}
  @isDocked={{this.navIsDocked}}
>
  <:button as |handlers|>
    <EuiButton {{on 'click' this.openCollapsibleNav}} {{handlers}}>
      Toggle nav
    </EuiButton>
  </:button>
  <:content>
    <EuiCollapsibleNavGroup
      @iconType='warning'
      @background='dark'
      @initialIsOpen={{false}}
      @isCollapsible={{true}}
    >
      <:title>
        Submenu 1
      </:title>
      <:content>
        This is the collapsible content!!!
      </:content>
    </EuiCollapsibleNavGroup>
    <EuiCollapsibleNavGroup
      @iconType='check'
      @background='light'
      @initialIsOpen={{false}}
      @isCollapsible={{true}}
    >
      <:title>
        Submenu 2
      </:title>
      <:content>
        <EuiButtonEmpty>
          I am a button 1
        </EuiButtonEmpty>
        <EuiButtonEmpty>
          I am a button 2
        </EuiButtonEmpty>
      </:content>
    </EuiCollapsibleNavGroup>
    <EuiCollapsibleNavGroup
      @iconType='warning'
      @initialIsOpen={{true}}
      @isCollapsible={{true}}
    >
      <:title>
        Submenu 3
      </:title>
      <:content>
        <EuiButton {{on 'click' this.toggleDockedNav}}>
          {{unless this.navIsDocked 'Dock it!' 'Undock it!'}}
        </EuiButton>
      </:content>
    </EuiCollapsibleNavGroup>
  </:content>
</EuiCollapsibleNav>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class DemoCollapsibleNavComponent extends Component {
  @tracked collNavIsOpen = false;
  @tracked navIsDocked = false;

  @action
  openCollapsibleNav() {
    this.collNavIsOpen = true;
  }

  @action
  closeCollapsibleNav() {
    this.collNavIsOpen = false;
  }

  @action
  toggleDockedNav() {
    this.navIsDocked = !this.navIsDocked;
  }
}
```
