---
order: 8
---

# Simple layout with centered body

<EuiText>
  Omit the side bar and header for a focused task. The template already creates
  and centers the content panel, so put the prompt directly in the default block.
</EuiText>

```hbs template
<EuiPageTemplate @template='centeredBody'>
  <:default>
    <EuiEmptyPrompt
      @iconType='search'
      @title='No projects yet'
      @body='Create a project to get started.'
    />
  </:default>
</EuiPageTemplate>
```
