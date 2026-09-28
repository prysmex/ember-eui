---
order: 1
---

# Video at 16 by 9

<EuiText>

The iframe fills the box, which keeps the ratio as the page resizes.

</EuiText>

```hbs template
<EuiAspectRatio @width={{16}} @height={{9}}>
  <iframe
    title="Elastic is a search company"
    src="https://www.youtube.com/embed/yJarWSLRM24"
    allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
    allowfullscreen
  ></iframe>
</EuiAspectRatio>
```
