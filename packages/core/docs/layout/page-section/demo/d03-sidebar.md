---
order: 3
---

# With a sidebar

<EuiText>

A row `EuiPage` with an `EuiPageSidebar` before the body. Narrow the window
below the `s` breakpoint to see the sidebar stack above the content.

</EuiText>

```hbs template
<EuiPage @paddingSize="none" style="border: 1px dashed #98A2B3">
  <EuiPageSidebar @paddingSize="m" @hasEmbellish={{true}} @minWidth={{200}}>
    <EuiListGroup @maxWidth={{false}}>
      <EuiListGroupItem @label="Overview" @isActive={{true}} />
      <EuiListGroupItem @label="Settings" />
      <EuiListGroupItem @label="Members" />
    </EuiListGroup>
  </EuiPageSidebar>
  <EuiPageBody>
    <EuiPageSection @bottomBorder={{true}}>
      <EuiTitle @size="m"><h2>Overview</h2></EuiTitle>
    </EuiPageSection>
    <EuiPageSection @color="plain" @grow={{true}}>
      <EuiText><p>Page content.</p></EuiText>
    </EuiPageSection>
  </EuiPageBody>
</EuiPage>
```
