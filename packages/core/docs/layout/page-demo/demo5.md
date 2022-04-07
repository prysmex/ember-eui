---
order: 5
---

# Centered Content
<EuiSpacer />
<EuiText>
  Similar to the previous example, you can create a centered panel to emphasize incompleteness even with a page header. For this setup, we recommend using setting <strong>EuiPageContent</strong> to use the <EuiCode>subdued</EuiCode> color as to not have nested shadows.
</EuiText>
<EuiSpacer />
<EuiCallOut>
  <:title>
    This layout can be achieved in <strong>EuiPageTemplate</strong> by setting <EuiCode>template="centeredContent"</EuiCode>.
  </:title>
</EuiCallOut>

```hbs template
<EuiPageTemplate
  @grow={{true}}
  @template='centeredContent'
  @pageHeader={{hash
    iconType='logoElastic'
    pageTitle='Page Title'
    rightSideItems=(array (component 'eui-button-title' title='Go full screen'))
  }}
  @pageSideBar={{component 'eui-loading-content' lines=8}}
>
  <EuiEmptyPrompt @paddingSize="l" @title='No spice' @body={{component 'eui-loading-content' lines=8}}/>
</EuiPageTemplate>
```
