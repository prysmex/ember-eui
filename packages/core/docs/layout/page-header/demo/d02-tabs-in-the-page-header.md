---
order: 2
---

# Tabs in the page header

```hbs template
<EuiPageHeader
  @bottomBorder={{true}}
	@pageTitle="Page title"
	@tabs={{array (hash label="Tab 1" isSelected=true) (hash label="Tab 2")}}
>
  <:rightSideItems>
    <EuiFlexItem>
      <EuiButton @fill={{true}}>Add something</EuiButton>
    </EuiFlexItem>
    <EuiFlexItem>
      <EuiButton>Do something</EuiButton>
    </EuiFlexItem>
  </:rightSideItems>
</EuiPageHeader>
```