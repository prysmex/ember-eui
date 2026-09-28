---
order: 2
---

# Characters

<EuiText>

`@granularity="characters"` marks the changed letters, for short values
like ids or names.

</EuiText>

```hbs template
<EuiText>
  <p><EuiTextDiff @beforeText="order-2024-00117" @afterText="order-2025-00171" @granularity="characters" /></p>
  <p><EuiTextDiff @beforeText="Jonathon Smith" @afterText="Jonathan Smyth" @granularity="characters" /></p>
</EuiText>
```
