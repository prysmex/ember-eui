---
order: 1
---

```hbs template
<EuiPageHeader
  @bottomBorder={{true}}
  @pageTitle="Page Title"
  @iconType='logoKibana'
  @description='This description should be describing the current page as depicted by the page title. It will never extend beneath the right side content.'
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