---
order: 2
---

# Custom label

<EuiText>

The `<:label>` block takes markup instead of `@label`.

</EuiText>

```hbs template
<EuiRadio @name="shipping" @checked={{true}}>
  <:label>
    Express <EuiBadge @color="success">Free</EuiBadge>
  </:label>
</EuiRadio>
```
