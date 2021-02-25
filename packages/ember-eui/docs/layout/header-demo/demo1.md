# Demo

```hbs template
<EuiButtonEmpty {{on "click" (fn this.toggleHeaderPosition "header1Fixed")}}>
  Toggle Header 1
</EuiButtonEmpty>
<EuiButtonEmpty {{on "click" (fn this.toggleHeaderPosition "header2Fixed")}}>
  Toggle Header 2
</EuiButtonEmpty>
<EuiHeader @position={{if this.header1Fixed "fixed"}}>
  <EuiHeaderSection @side="left">
    <EuiHeaderSectionItem @border="right">
      <EuiHeaderLogo @href="">
        Header 1
      </EuiHeaderLogo>
    </EuiHeaderSectionItem>
    <EuiHeaderSectionItem @border="right">
      <EuiHeaderSectionItemButton>
        <EuiAvatar @name="Planta Prysmex" @type="space" @initialLength={{2}} @size="s" />
      </EuiHeaderSectionItemButton>
    </EuiHeaderSectionItem>
  </EuiHeaderSection>
  <EuiHeaderSection @side="right">
    <EuiHeaderSectionItem @border="left">
      <EuiHeaderSectionItemButton @notification="3" @notificationColor="accent">
        <EuiIcon @type="bell" @size="m" />
      </EuiHeaderSectionItemButton>
    </EuiHeaderSectionItem>
    <EuiHeaderSectionItem @border="left">
      <EuiHeaderSectionItemButton>
        <EuiAvatar @name="David Martinez" @type="user" @initialLength={{2}} @size="m" />
      </EuiHeaderSectionItemButton>
    </EuiHeaderSectionItem>
  </EuiHeaderSection>
</EuiHeader>
<EuiHeader @theme="dark" @position={{if this.header2Fixed "fixed"}}>
  <EuiHeaderSectionItem @border="right">
    <EuiHeaderLogo @href="">
      Header 2
    </EuiHeaderLogo>
  </EuiHeaderSectionItem>
</EuiHeader>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class DemoHeaderComponent extends Component {
  @tracked header1Fixed = false;
  @tracked header2Fixed = false;

  @action
  toggleHeaderPosition(header) {
    this[header] = !this[header];
  }
}
```
