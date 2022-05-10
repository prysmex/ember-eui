---
order: 6
---

# A simple page with tabs

<EuiText>
  When leaving off the <strong>EuiPageSideBar</strong>, we recommend a slightly different configuration by pulling the page header out of the <strong>EuiPageContent</strong> and removing the shadow from <strong>EuiPageContent</strong>.
</EuiText>
<EuiSpacer />
<EuiCallOut>
  <:title>
    This layout will automatically be achieved through <strong>EuiPageTemplate</strong> by leaving <EuiCode>pageSideBar</EuiCode> as <EuiCode>undefined</EuiCode>.
  </:title>
</EuiCallOut>

```hbs template
<EuiPageTemplate
  @grow={{true}}
  @pageHeader={{hash
    iconType='logoElastic'
    pageTitle='Page Title'
    tabs=this.tabs
  }}
>
  <:pageHeaderRightSideItems as |Item|>
    <Item>
      <EuiButton>
        Go to full screen
      </EuiButton>
    </Item>
  </:pageHeaderRightSideItems>
  <:default>
    <EuiLoadingContent @lines={{16}} />
  </:default>
</EuiPageTemplate>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class DemoIconComponent extends Component {
  tabs = [
    { label: 'Tab 1', isSelected: true },
    {
      label: 'Tab 2',
      onClick: this.setShowBottomBar
    }
  ];
  @tracked showing = false;

  @action
  setSHowBottomBar() {
    this.showing = !this.showing;
  }
}
```
