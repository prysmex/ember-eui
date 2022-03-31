---
order: 3
---

# Alignment

<EuiText>
  <p>
There are two ways to align text. Either individually by applying <strong>EuiTextAlign</strong> on individual text objects, or by passing the <EuiCode>textAlign</EuiCode> prop directly on <strong>EuiText</strong> for a blanket approach across the entirety of your text.

  </p>
</EuiText>

```hbs template
<div>
  <EuiText>
    <EuiTextAlign @textAlign='left'>
      <p>Left aligned paragraph.</p>
    </EuiTextAlign>
    <EuiTextAlign @textAlign='center'>
      <p>Center aligned paragraph.</p>
    </EuiTextAlign>
    <EuiTextAlign @textAlign='right'>
      <p>Right aligned paragraph.</p>
    </EuiTextAlign>
  </EuiText>
  <EuiSpacer />
  <EuiText @textAlign='center'>
    <p>
      You can also pass alignment to
      <strong>EuiText</strong>
      directly with a prop
    </p>
  </EuiText>
  <EuiText @textAlign='center' @color='success'>
    <p>And in conjunction with coloring.</p>
  </EuiText>
</div>
```
