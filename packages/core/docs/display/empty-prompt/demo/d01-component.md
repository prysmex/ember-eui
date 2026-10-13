---
order: 1
---

# Component

<EuiText>

While no one piece of content is required, each **EuiEmptyPrompt** should contain at least a `@title` and/or a `@body`. They usually contain one or more `@actions` that promotes the primary call-to-actions. You can also provide a `<:footer>` to direct users towards making informed decisions.

</EuiText>

```hbs template
<EuiEmptyPrompt
  @iconType="logoSecurity"
  @title="Start adding cases"
  @body="Add a new case or change your filter settings."
  @actions={{array (component "eui-button-title" title="Add a case" color="primary")}}
>
  <:footer>
    <EuiTitle @size="xxs"><h3>Want to learn more?</h3></EuiTitle>
    <EuiLink @href="#" @target="_blank">Read the docs</EuiLink>
  </:footer>
</EuiEmptyPrompt>
```
