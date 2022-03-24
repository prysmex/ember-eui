---
order: 5
---

```hbs template
<EuiTitle @size='s'>
  Dark theme
</EuiTitle>
<EuiSpacer />
<EuiText>
  To make site-wide navigation more prominent,
  <strong>EuiHeader</strong>
  supports reversing the colors to dark theme with
  <EuiCode>theme="dark"</EuiCode>. However, it only supports a
  <strong>limited set of children</strong>
  that will also shift their theme. These components include
  <strong>EuiHeaderLogo</strong>,
  <strong>EuiHeaderLink(s)</strong>,
  <strong>EuiHeaderSectionItemButton</strong>
  and
  <strong>EuiSelectableTemplateSitewide</strong>. Any other content may not
  render correctly without custom configurations.
</EuiText>
<EuiSpacer />
<EuiHeader @theme='dark'>
  <EuiHeaderSection @side='left'>
    <EuiHeaderSectionItem @border='right'>
      <EuiHeaderLogo>Elastic</EuiHeaderLogo>
    </EuiHeaderSectionItem>
    <EuiHeaderSectionItem @border='right'>
      <EuiHeaderLinks @gutterSize='xs'>
        <EuiHeaderLink @isActive={{true}}>Docs</EuiHeaderLink>
        <EuiHeaderLink>Code</EuiHeaderLink>
        <EuiHeaderLink @iconType='help'>Help</EuiHeaderLink>
      </EuiHeaderLinks>
    </EuiHeaderSectionItem>
  </EuiHeaderSection>
  <EuiHeaderSection @side='left'>
    <EuiHeaderSectionItem @border='left'>
      <EuiBadge @iconType='arrowDown' @iconSide='right'>
        Production logs
      </EuiBadge>
    </EuiHeaderSectionItem>
    <EuiHeaderSectionItem @border='left'>
      <EuiHeaderSectionItemButton
        aria-label='2 Notifications'
        @notification={{'2'}}
      >
        <EuiIcon @type='cheer' size='m' />
      </EuiHeaderSectionItemButton>
    </EuiHeaderSectionItem>
    <EuiHeaderSectionItem @border='left'>
      <EuiHeaderSectionItemButton aria-label='Account menu'>
        <EuiAvatar @name='John Username' @size='s' />
      </EuiHeaderSectionItemButton>
    </EuiHeaderSectionItem>
  </EuiHeaderSection>
</EuiHeader>
```