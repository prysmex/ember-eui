---
order: 9
---

# Simple layout with centered content

<EuiText>
 The centeredContent template creates the nested containers needed to center the prompt below a header. Omit the side bar block and put the prompt directly in the default block; no extra EuiPageContent is needed.
</EuiText>

```hbs template
<EuiPageTemplate
  @template='centeredContent'
  @pageContentProps={{hash paddingSize='none'}}
  @pageHeader={{hash iconType='logoElastic' pageTitle='Page Title'}}
>
  <:pageHeaderRightSideItems as |Item|>
    <Item>
      <EuiButton @fill={{true}}>
        Go to full screen
      </EuiButton>
    </Item>
  </:pageHeaderRightSideItems>
  <:default>
    <EuiEmptyPrompt @paddingSize='l'>
      <:content>
        <EuiTitle>No spice</EuiTitle>
        <EuiSpacer />
        <EuiText>
          <figure class='euiImage euiImage--fullWidth'><img
              src='data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNjQ2IiBoZWlnaHQ9IjEyMCIgdmlld0JveD0iMCAwIDY0NiAxMjAiIGZpbGw9Im5vbmUiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+CjxnIG9wYWNpdHk9IjAuNDE1Ij4KPHJlY3Qgd2lkdGg9IjY0NiIgaGVpZ2h0PSIyNCIgcng9IjQiIGZpbGw9IiM3RDg2OUMiIGZpbGwtb3BhY2l0eT0iMC41Ii8+CjxyZWN0IHk9IjQ4IiB3aWR0aD0iNjQ2IiBoZWlnaHQ9IjI0IiByeD0iNCIgZmlsbD0iIzdEODY5QyIgZmlsbC1vcGFjaXR5PSIwLjUiLz4KPHJlY3QgeD0iMTM2LjUiIHk9Ijk2IiB3aWR0aD0iMzczIiBoZWlnaHQ9IjI0IiByeD0iNCIgZmlsbD0iIzdEODY5QyIgZmlsbC1vcGFjaXR5PSIwLjUiLz4KPC9nPgo8L3N2Zz4K'
              class='euiImage__img'
              alt='Fake paragraph'
              title=''
              style=''
            /></figure>
        </EuiText>
      </:content>
    </EuiEmptyPrompt>
  </:default>

</EuiPageTemplate>
```
