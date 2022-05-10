---
order: 5
---

<EuiText>
	A common pattern is to use a single breadcrumb to return the user to a listing page from which the current page was navigated to
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