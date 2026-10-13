---
order: 2
---

# Formatting numbers

<EuiText>

`EuiI18nNumber` renders `@value` formatted, or yields it to a block. With
`@values` it yields an array of formatted numbers.

</EuiText>

```hbs template
<EuiText>
  <p>Documents: <EuiI18nNumber @value={{1234567}} /></p>
  <p>Average size: <EuiI18nNumber @value={{2048.75}} /> bytes</p>
  <EuiI18nNumber @values={{array 3000 12000}} as |counts|>
    <p>Shards: {{get counts "0"}} primary, {{get counts "1"}} replica</p>
  </EuiI18nNumber>
</EuiText>
```
