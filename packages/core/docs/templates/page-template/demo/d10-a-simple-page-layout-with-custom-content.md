---
order: 10
---

# A simple page layout with custom content

<EuiText>
 Use the empty template for dashboard layouts with your own panels, with or without a page header. This example omits the side bar and removes the width limit; the final example shows custom content with a side bar.
</EuiText>
<EuiSpacer />
<EuiCallOut>
  <:body>
    This layout can be achieved in <strong>EuiPageTemplate</strong> by setting <EuiCode>@template="empty"</EuiCode>.
  </:body>
</EuiCallOut>

```hbs template
<EuiPageTemplate
  @grow={{true}}
  @restrictWidth={{false}}
  @template='empty'
  @pageHeader={{hash
    iconType='logoElastic'
    pageTitle='Page Title'
    bottomBorder=true
  }}
>
  <:pageHeaderRightSideItems as |Item|>
    <Item>
      <EuiButton @color='warning'>
        Go to full screen
      </EuiButton>
    </Item>
    <Item>
      <EuiButton>
        Do something
      </EuiButton>
    </Item>
  </:pageHeaderRightSideItems>
  <:default>
    <EuiFlexGrid @columns={{2}}>
      <EuiFlexItem>
        <EuiPanel style='height: 200px' />
      </EuiFlexItem>
      <EuiFlexItem>
        <EuiPanel style='height: 200px' />
      </EuiFlexItem>
      <EuiFlexItem>
        <EuiPanel style='height: 200px' />
      </EuiFlexItem>
      <EuiFlexItem>
        <EuiPanel style='height: 200px' />
      </EuiFlexItem>
    </EuiFlexGrid>
  </:default>

</EuiPageTemplate>
```
