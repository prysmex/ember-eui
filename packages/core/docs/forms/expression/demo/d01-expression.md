---
order: 1
---

# Expression

<EuiText>

Read-only expressions, in the colors available with `@color`.

</EuiText>

```hbs template
<EuiExpression @description="when" @value="avg()" />
<EuiExpression @description="of" @value="bytes" @color="accent" />
<EuiExpression @description="is above" @value="100" @color="primary" />
<EuiExpression @description="for the last" @value="5 minutes" @color="warning" />
<EuiExpression @description="except" @value="internal traffic" @color="danger" />
<EuiExpression @description="grouped over" @value="all documents" @color="subdued" />
```
