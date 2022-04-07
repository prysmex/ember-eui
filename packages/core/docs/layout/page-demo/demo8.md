---
order: 8
---

# Simple layout with centered body

<EuiText>
 Similar to the version with a side bar, when the content for the page is minimal or in an empty/pre-setup state, the page content can be centered vertically and horizontally. We recommend then using the <strong>EuiEmptyPrompt</strong> for the content.
</EuiText>

```hbs template
<EuiPageTemplate @grow={{true}} @template='centeredBody'>
  <EuiEmptyPrompt
    @title='No spice'
    @paddingSize='l'
    @body={{component 'eui-loading-content' lines=4}}
  />
</EuiPageTemplate>
```
