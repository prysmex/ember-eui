---
order: 3
---

# Header links

<EuiText>

In addition to the components mentioned prior, which lend themselves to more application style navigation patterns, `EuiHeaderLinks` and `EuiHeaderLink` supply the ability to inline a list of navigational or menu style links.

`EuiHeaderLinks` comes with responsive functionality built-in which will convert the inline list of links to a popover list triggered by a `EuiHeaderSectionItemButton`. You can adjust at which breakpoints to switch to the popover display by passing your own array of named breakpoints to `@popoverBreakpoints`. The block yields a function that closes the popover, which you can call from a link's `@onClick` (upstream's render-prop `closeMobilePopover`).

</EuiText>

```hbs template
<EuiHeader>
  <EuiHeaderSectionItem>
    <EuiHeaderLogo @iconType="logoElastic">Elastic</EuiHeaderLogo>
  </EuiHeaderSectionItem>

  <EuiHeaderSectionItem>
    <EuiHeaderLinks aria-label="App navigation links example" as |closeMobilePopover|>
      <EuiHeaderLink @isActive={{true}} @onClick={{closeMobilePopover}}>Docs</EuiHeaderLink>

      <EuiHeaderLink @onClick={{closeMobilePopover}}>Code</EuiHeaderLink>

      <EuiHeaderLink @iconType="help" @onClick={{closeMobilePopover}}>Help</EuiHeaderLink>
    </EuiHeaderLinks>
  </EuiHeaderSectionItem>
</EuiHeader>
```
