---
order: 2
---

# Sections

<EuiText>

A header has a left and a right `EuiHeaderSection`. Each holds
`EuiHeaderSectionItem`s, separated by a border on the `@border` side.
`@grow={{true}}` on a section lets it take the remaining width, e.g. for
a search bar.

</EuiText>

```hbs template
<EuiHeader>
  <EuiHeaderSection @side="left">
    <EuiHeaderSectionItem @border="right">
      <EuiHeaderLogo @iconType="logoElastic" @href="#">Acme</EuiHeaderLogo>
    </EuiHeaderSectionItem>
  </EuiHeaderSection>

  <EuiHeaderSection @grow={{true}}>
    <EuiHeaderSectionItem @border="none">
      <EuiFieldSearch @compressed={{true}} aria-label="Search" placeholder="Search…" />
    </EuiHeaderSectionItem>
  </EuiHeaderSection>

  <EuiHeaderSection @side="right">
    <EuiHeaderSectionItem>
      <EuiHeaderSectionItemButton aria-label="Help">
        <EuiIcon @type="help" />
      </EuiHeaderSectionItemButton>
    </EuiHeaderSectionItem>
    <EuiHeaderSectionItem>
      <EuiHeaderSectionItemButton aria-label="Account">
        <EuiAvatar @name="Jane Cooper" @size="s" />
      </EuiHeaderSectionItemButton>
    </EuiHeaderSectionItem>
  </EuiHeaderSection>
</EuiHeader>
```
