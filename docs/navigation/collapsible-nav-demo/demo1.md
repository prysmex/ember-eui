# Demo

```hbs template
<EuiTitle @size="s">
  Collapsible Nav
</EuiTitle>
<EuiCollapsibleNav
  @isOpen={{this.collNavIsOpen}}
  @onClose={{this.closeCollapsibleNav}}
  @showCloseButton={{true}}
  @navIsDocked={{this.navIsDocked}}
>
  <:button>
    <EuiButton @onClick={{this.openCollapsibleNav}}>
      Open Collapsible Nav
    </EuiButton>
  </:button>
  <:content>
    <EuiCollapsibleNavGroup
      @iconType="alert"
      @background="dark"
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
      @iconType="check"
      @background="light"
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
    <EuiCollapsibleNavGroup @iconType="alert" @initialIsOpen={{true}} @isCollapsible={{true}}>
      <:title>
        Submenu 3
      </:title>
      <:content>
        <EuiButton @onClick={{this.toggleDockedNav}}>
          {{unless this.navIsDocked "Dock it!" "Undock it!"}}
        </EuiButton>
      </:content>
    </EuiCollapsibleNavGroup>
  </:content>
</EuiCollapsibleNav>
<EuiSpacer />
<EuiTitle @size="s">
  Collapsible Nav Group
</EuiTitle>
<EuiSpacer />
<EuiCollapsibleNavGroup>
  <:content>
    BASIC WITH NOTHING
  </:content>
</EuiCollapsibleNavGroup>
<EuiCollapsibleNavGroup @iconType="alert" @background="light">
  <:title>
    Hello My friends!
  </:title>
  <:content>
    This is not collapsible! But the bottom one is!
  </:content>
</EuiCollapsibleNavGroup>
<EuiCollapsibleNavGroup
  @iconType="alert"
  @background="dark"
  @initialIsOpen={{false}}
  @isCollapsible={{true}}
>
  <:title>
    Click me!!
  </:title>
  <:content>
    This is the collapsible content!!!
  </:content>
</EuiCollapsibleNavGroup>
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