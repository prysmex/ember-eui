---
order: 1
---

<EuiText>

<p>The <strong>EuiProgress</strong> component by default will display in an indeterminate loading state (rendered as a single div) until you define a <EuiCode @language="text">max</EuiCode> and <EuiCode @language="text">value</EuiCode> prop. The <EuiCode @language="text">size</EuiCode> prop refers to its vertical height. It will always stretch <EuiCode @language="text">100%</EuiCode> to its container.</p>

</EuiText>

```hbs template
<div>
  <EuiProgress @size='xs' @color='accent' />
</div>
```
