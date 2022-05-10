---
order: 4
---

# Centered body

<EuiSpacer />
<EuiText>
  When the content for the page is minimal or in an empty/pre-setup state, the page content can be centered vertically and horizontally. We recommend then using the <strong>EuiEmptyPrompt</strong> for the content.
</EuiText>
<EuiSpacer />
<EuiCallOut>
  <:title>
    This layout can be achieved in <strong>EuiPageTemplate</strong> by setting <EuiCode>template="centeredBody"</EuiCode>.
  </:title>
</EuiCallOut>

```hbs template
<EuiPageTemplate @template='centeredBody' @grow={{true}}>
  <:pageSideBar>
    <EuiLoadingContent @lines={{8}} />
  </:pageSideBar>
  <:default>
    <EuiEmptyPrompt @paddingSize='l'>
      <:content>
        <EuiTitle>No spice</EuiTitle>
        <EuiSpacer />
        <figure class='euiImage euiImage--fullWidth'><img
            src='data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNjQ2IiBoZWlnaHQ9IjEyMCIgdmlld0JveD0iMCAwIDY0NiAxMjAiIGZpbGw9Im5vbmUiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+CjxnIG9wYWNpdHk9IjAuNDE1Ij4KPHJlY3Qgd2lkdGg9IjY0NiIgaGVpZ2h0PSIyNCIgcng9IjQiIGZpbGw9IiM3RDg2OUMiIGZpbGwtb3BhY2l0eT0iMC41Ii8+CjxyZWN0IHk9IjQ4IiB3aWR0aD0iNjQ2IiBoZWlnaHQ9IjI0IiByeD0iNCIgZmlsbD0iIzdEODY5QyIgZmlsbC1vcGFjaXR5PSIwLjUiLz4KPHJlY3QgeD0iMTM2LjUiIHk9Ijk2IiB3aWR0aD0iMzczIiBoZWlnaHQ9IjI0IiByeD0iNCIgZmlsbD0iIzdEODY5QyIgZmlsbC1vcGFjaXR5PSIwLjUiLz4KPC9nPgo8L3N2Zz4K'
            class='euiImage__img'
            alt='Fake paragraph'
            title=''
            style=''
          /></figure>
        <EuiSpacer />
        <EuiButton @fill={{true}}>
          Go to full screen
        </EuiButton>
      </:content>
    </EuiEmptyPrompt>
  </:default>
</EuiPageTemplate>
```
