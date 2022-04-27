---
order: 9
---

# Simple layout with centered content

<EuiText>
 Also similar to the previous examples, you can create a centered panel to emphasis incompleteness even with a page header. For this setup, You will need to use nested <strong>EuiPageContent</strong> components in order for the centering to work.
</EuiText>

```hbs template
<EuiPageTemplate
  @template='centeredContent'
  @pageContentProps={{hash paddingSize='none'}}
  @pageHeader={{hash iconType='logoElastic' pageTitle='Page Title'}}
>
  <:pageHeaderRightSideItems as |Item|>
    <Item>
      <EuiButton>
        Go to full screen
      </EuiButton>
    </Item>
  </:pageHeaderRightSideItems>
  <:default>
    <EuiEmptyPrompt
      @title='No spice'
      @paddingSize='l'
      @body={{component 'eui-loading-content' lines=4}}
    />
  </:default>

</EuiPageTemplate>
```
