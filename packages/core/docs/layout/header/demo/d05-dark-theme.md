---
order: 5
---

# Dark theme

<EuiText>
  <p>
  To make site-wide navigation more prominent, <strong>EuiHeader</strong> supports reversing the colors to dark theme with <EuiCode>theme="dark"</EuiCode>. However, it only supports a <strong>limited set of children</strong> that will also shift their theme. These components include <strong>EuiHeaderLogo</strong>, <strong>EuiHeaderLink(s)</strong>, <strong>EuiHeaderSectionItemButton</strong> and <strong>EuiSelectableTemplateSitewide</strong>. Any other content may not render correctly without custom configurations.
  </p>
</EuiText>

```hbs template
<EuiHeader @theme='dark'>
  <EuiHeaderSection @side='left' @border='right'>
    <EuiHeaderSectionItem>
      <EuiHeaderLogo>Elastic</EuiHeaderLogo>
    </EuiHeaderSectionItem>
    <EuiHeaderSectionItem>
      <EuiHeaderLinks aria-label='App navigation dark theme example'>
        <EuiHeaderLink @isActive={{true}}>Docs</EuiHeaderLink>
        <EuiHeaderLink>Code</EuiHeaderLink>
        <EuiHeaderLink @iconType='help'> Help</EuiHeaderLink>
      </EuiHeaderLinks>
    </EuiHeaderSectionItem>

  </EuiHeaderSection>
  <EuiHeaderSection @side='right'>
    <EuiHeaderSectionItem @border='left'>
      <EuiBadge @iconType='arrowDown' @iconSide='right'>
        Production logs
      </EuiBadge>
    </EuiHeaderSectionItem>
    <EuiHeaderSectionItem>
      <EuiHeaderSectionItemButton
        @notification='2'
        aria-label='2 Notifications'
      >
        <EuiIcon @type='cheer' @size='m' />
      </EuiHeaderSectionItemButton>
    </EuiHeaderSectionItem>

    <EuiHeaderSectionItem>
      <EuiHeaderSectionItemButton aria-label='Account menu'>
        <EuiAvatar @name='John Username' @size='s' />
      </EuiHeaderSectionItemButton>
    </EuiHeaderSectionItem>

  </EuiHeaderSection>
</EuiHeader>
```

```js component
import Component from '@glimmer/component';

export default class DemoHeaderComponent extends Component {}
```
