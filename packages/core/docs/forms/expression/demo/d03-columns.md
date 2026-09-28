---
order: 3
---

# Columns

<EuiText>

`@display="columns"` puts the description and value side by side, so
several expressions line up. `@descriptionWidth` sets the description's
width (defaults to `20%`); `@textWrap="truncate"` cuts long values.

</EuiText>

```hbs template
<div style="max-width: 360px;">
  <EuiExpression @display="columns" @descriptionWidth={{70}} @description="index" @value="logs-*" />
  <EuiExpression @display="columns" @descriptionWidth={{70}} @description="where" @value="status is 500" @color="accent" />
  <EuiExpression
    @display="columns"
    @descriptionWidth={{70}}
    @description="and"
    @value="url.path matches /api/v2/customers/*/invoices/*/download"
    @color="accent"
    @textWrap="truncate"
  />
</div>
```
