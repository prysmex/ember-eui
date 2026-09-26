---
order: 1
---

# Empty prompt

```hbs template
<EuiEmptyPrompt
  @iconType="logoSecurity"
  @title="Start adding cases"
  @body="There are no cases to display. Add a new case or change your filter settings."
  @actions={{array (component "eui-button-title" title="Add a case")}}
>
  <:footer>
    <EuiTitle @size="xxs" @tagName="h3">Want to learn more?</EuiTitle>
    <EuiLink href="#" target="_blank">
      Read documentation
    </EuiLink>
  </:footer>
</EuiEmptyPrompt>
```
