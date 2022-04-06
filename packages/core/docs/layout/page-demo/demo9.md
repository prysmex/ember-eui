---
order: 9
---

# Simple layout with centered content

<EuiText>
 Also similar to the previous examples, you can create a centered panel to emphasis incompleteness even with a page header. For this setup, You will need to use nested <strong>EuiPageContent</strong> components in order for the centering to work.
</EuiText>

```hbs template
<EuiPageTemplate
  @grow={{true}}
  @template='centeredContent'
  @paddingSize="l"
  @pageHeader={{hash
    iconType='logoElastic'
    pageTitle='Page Title'
    rightSideItems='eui-button'
  }}
>
  <EuiEmptyPrompt
    @title='No spice'
    @paddingSize="l"
    @body={{component 'eui-loading-content' lines=4}}
  />
</EuiPageTemplate>
```
