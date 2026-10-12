---
order: 1
---

# Text

<EuiText>

`EuiSkeletonText` draws `@lines` placeholder lines (3 by default) with the
line height of an `EuiText` of the same `@size`: `'m'`, `'s'`, `'xs'`, or
`'relative'` to follow the surrounding font size.

</EuiText>

```hbs template
<EuiSkeletonText @lines={{3}} />
<EuiSpacer />
<EuiSkeletonText @lines={{2}} @size="s" />
<EuiSpacer />
<EuiSkeletonText @lines={{2}} @size="xs" />
```
