---
order: 3
---

```hbs template
<EuiTitle @size='s'>
  Header links
</EuiTitle>
<EuiSpacer />
<EuiText>
  In addition to the components mentioned prior, which lend themselves to more
  application style navigation patterns,
  <strong>EuiHeaderLinks</strong>
  and
  <strong>EuiHeaderLink</strong>
  supply the ability to inline a list of navigational or menu style links.
  <strong>EuiHeaderLinks</strong>
  comes with responsive functionality built-in which will convert the inline
  list of links to a popover list triggered by a
  <strong>EuiHeaderSectionItemButton</strong>. You can adjust at which
  breakpoints to switch to the popover display by passing your own array of
  named breakpoints to
  <EuiCode>popoverBreakpoints</EuiCode>.
</EuiText>
<EuiHeader>
  <EuiHeaderSection @side='left'>
    <EuiHeaderSectionItem @border='right'>
      <EuiHeaderLogo>Elastic</EuiHeaderLogo>
    </EuiHeaderSectionItem>
  </EuiHeaderSection>
  <EuiHeaderSection @side='right'>
    <EuiHeaderSectionItem @border='left'>
      <EuiHeaderLinks @gutterSize='xs' @popoverBreakpoints='s'>
        <EuiHeaderLink @isActive={{true}}>Docs</EuiHeaderLink>
        <EuiHeaderLink>Code</EuiHeaderLink>
        <EuiHeaderLink @iconType='help'>Help</EuiHeaderLink>
      </EuiHeaderLinks>
    </EuiHeaderSectionItem>
  </EuiHeaderSection>
</EuiHeader>
```
