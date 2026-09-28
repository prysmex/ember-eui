---
order: 2
---

# Maximum width

<EuiText>

`@maxWidth` stops it from growing past a width (a number in px, or any
CSS length); the ratio is kept below that.

</EuiText>

```hbs template
<EuiAspectRatio @width={{1}} @height={{1}} @maxWidth={{300}}>
  <img
    src="https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=600"
    alt="A lake between mountains"
    style="object-fit: cover;"
  />
</EuiAspectRatio>
```
