---
order: 2
---

# Text sizes

<EuiText>
  <p>Match the text size of <strong>EuiHealth</strong> to your context by passing <EuiCode @language="text">xs / s / m / inherit</EuiCode> to the <EuiCode @language="text">textSize</EuiCode> prop. The <EuiCode @language="text">inherit</EuiCode> style will get its font size from the parent element.</p>
</EuiText>

```hbs template
<EuiHealth @color='subdued' @textSize='xs'>
  Inactive
</EuiHealth>
<EuiSpacer />
<EuiHealth @color='primary' @textSize='s'>
  Active
</EuiHealth>
<EuiSpacer />
<EuiHealth @color='success' @textSize='m'>
  Healthy
</EuiHealth>
<EuiSpacer />
<EuiTitle @size='s'>
  <h3>
    <EuiHealth @color='warning' @textSize='inherit'>
      Warning
    </EuiHealth>
  </h3>
</EuiTitle>
```
