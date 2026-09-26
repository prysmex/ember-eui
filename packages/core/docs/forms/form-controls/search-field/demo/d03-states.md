---
order: 3
---

# Loading, compressed and full width

<EuiText>

`@isLoading` shows a spinner while results load, `@compressed` fits dense
toolbars, `@fullWidth` fills the container and `@isClearable={{false}}`
hides the clear button.

</EuiText>

```hbs template
<EuiFieldSearch @value="kibana" @isLoading={{true}} aria-label="Loading search" />
<EuiSpacer />
<EuiFieldSearch @value="compact" @compressed={{true}} aria-label="Compressed search" />
<EuiSpacer />
<EuiFieldSearch
  @value="no clear button"
  @isClearable={{false}}
  @fullWidth={{true}}
  aria-label="Full width search"
/>
```
