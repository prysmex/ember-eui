---
order: 5
---

# Dark theme

<EuiText>

To make site-wide navigation more prominent, `EuiHeader` supports reversing the colors to dark theme with `@theme="dark"`. However, it only supports a **limited set of children** that will also shift their theme. These components include `EuiHeaderLogo`, `EuiHeaderLink(s)`, `EuiHeaderSectionItemButton` and `EuiSelectableTemplateSitewide`. Any other content may not render correctly without custom configurations.

</EuiText>

```hbs template
<EuiHeader @theme='dark'>
  <EuiHeaderSection @side='left'>
    <EuiHeaderSectionItem>
      <EuiHeaderLogo @iconType="logoElastic">Elastic</EuiHeaderLogo>
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
    <EuiHeaderSectionItem>
      <EuiBadge @iconType='chevronSingleDown' @iconSide='right'>
        Production logs
      </EuiBadge>
    </EuiHeaderSectionItem>
    <EuiHeaderSectionItem>
      <EuiHeaderSectionItemButton
        @notification='2'
        aria-label='2 Notifications'
      >
        <EuiIcon @type='popper' @size='m' />
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

export default class DarkHeaderDemo extends Component {}
```
