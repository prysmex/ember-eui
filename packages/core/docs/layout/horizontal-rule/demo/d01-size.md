---
order: 1
---

# Size

<EuiText>

`EuiHorizontalRule` is a styled `<hr>` element. It can be one of three provided sizes (lengths), by default it will be `full`.

</EuiText>

```hbs template
<div class="eui-textCenter">
  <EuiCode>quarter</EuiCode>
  <EuiHorizontalRule @size="quarter" />
  <EuiCode>half</EuiCode>
  <EuiHorizontalRule @size="half" />
  <EuiCode>full (default)</EuiCode>
  <EuiHorizontalRule />
</div>
```