---
order: 2
---

# Tabs

```hbs template
<EuiPageHeader
  @bottomBorder={{true}}
	@pageTitle="Page title"
  @description='This description should be describing the current page as depicted by the page title. It will never extend beneath the right side content.'
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