---
order: 5
---

# A back link as a breadcrumb

<EuiText>

A breadcrumb's `text` can be a component, e.g. a small "Return" button,
for a single step back instead of a full trail.

</EuiText>

```hbs template
<EuiPageHeader
  @bottomBorder={{true}}
  @pageTitle='Page title'
  @description='Example of a description.'
  @breadcrumbs={{array
    (hash
      text=(component
        'eui-button-title'
        title='Return'
        iconType='arrowLeft'
        color='primary'
        size='s'
				buttonEmpty=true
      )
      href='http://www.elastic.co'
    )
  }}
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