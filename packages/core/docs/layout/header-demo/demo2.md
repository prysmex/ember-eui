---
order: 2
---

```hbs template
<EuiTitle @size='s'>
  Sections
</EuiTitle>
<EuiSpacer />
<EuiText>
  Alternatively, you can pass an array of objects to the <EuiCode>sections</EuiCode> prop that
  takes a key of <EuiCode>items</EuiCode> (array of children to wrap in an <strong>EuiHeaderSectionItem</strong>)
  and/or breadcrumbs (array of breadcrumb objects). Each item in the array will
  be wrapped in an <strong>EuiHeaderSection</strong>. <strong>Note</strong>: Passing <EuiCode>sections</EuiCode> and <EuiCode>children</EuiCode> will
  disregard the <EuiCode>children</EuiCode> as it is not easily interpreted at what location the
  children should be placed.
</EuiText>
<EuiHeader>
  <EuiHeaderSection @side='left'>
    <EuiHeaderSectionItem @border='right'>
      <EuiHeaderLogo
        @iconType='logoElastic'
        href='#'
        @onClick={{this.onClick}}
        aria-label='Go to home page'
      />
    </EuiHeaderSectionItem>
    <EuiHeaderSectionItem @border='right'>
      <EuiHeaderSectionItemButton>
        <EuiAvatar
          @name='Planta Prysmex'
          @type='space'
          @initialLength={{2}}
          @size='s'
        />
      </EuiHeaderSectionItemButton>
    </EuiHeaderSectionItem>
  </EuiHeaderSection>
  <EuiHeaderSection @side='right'>
    <EuiHeaderSectionItem @border='left'>
      <EuiHeaderSectionItemButton @disabled={{true}}>
        <EuiIcon @type='search' @size='m' />
      </EuiHeaderSectionItemButton>
    </EuiHeaderSectionItem>
    <EuiHeaderSectionItem @border='left'>
      <EuiHeaderSectionItemButton @notification='3' @notificationColor='accent'>
        <EuiIcon @type='bell' @size='m' />
      </EuiHeaderSectionItemButton>
    </EuiHeaderSectionItem>
    <EuiHeaderSectionItem @border='left'>
      <EuiHeaderSectionItemButton
        @notification='1'
        @notificationColor='accent'
        @disabled={{true}}
        aria-label='Apps menu with 1 new app'
      >
        <EuiIcon @type='apps' @size='m' />
      </EuiHeaderSectionItemButton>
    </EuiHeaderSectionItem>
  </EuiHeaderSection>
</EuiHeader>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class DemoHeaderComponent extends Component {
  @action
  onClick(e) {
    e.preventDefault();
  }

}
```
