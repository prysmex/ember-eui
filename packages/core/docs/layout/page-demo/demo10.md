---
order: 10
---

# A simple page layout with custom content

<EuiText>
 You can replace the inner parts of <strong>EuiPageBody</strong> with your own content, with or without a page header. This allows you to create dashboard style layouts with lots of panels. It is not recommended, however, to use this setup when you also have side bar.
</EuiText>
<EuiSpacer />
<EuiCallOut>
  <:body>
    This layout can be achieved in <strong>EuiPageTemplate</strong> by setting <EuiCode>template="empty"</EuiCode>.
  </:body>
</EuiCallOut>

```hbs template
<EuiPageTemplate
  @grow={{true}}
  @template='empty'
  @pageHeader={{hash
    iconType='logoElastic'
    pageTitle='Page Title'
    rightSideItems=(array (component 'eui-button-title' title='Go full screen' color='warning')(component 'eui-button-title' title='Do something'))
  }}
>
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
</EuiPageTemplate>
```
