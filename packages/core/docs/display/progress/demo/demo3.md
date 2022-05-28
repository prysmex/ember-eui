---
order: 3
---

# Sizes

<EuiText>
<p>You can adjust the <EuiCode @language="text">size</EuiCode> of both determinate and indeterminate progress bars.</p>
</EuiText>

```hbs template
<div>
  <EuiProgress @value='{{20}}' @max='{{100}}' @size='xs' />
  <EuiSpacer @size='l' />

  <EuiProgress @value='{{40}}' @max='{{100}}' @size='xs' />
  <EuiSpacer @size='l' />

  <EuiProgress @value='{{60}}' @max='{{100}}' @size='s' />
  <EuiSpacer @size='l' />

  <EuiProgress @value='{{80}}' @max='{{100}}' @size='m' />
  <EuiSpacer @size='l' />

  <EuiProgress @value='{{90}}' @max='{{100}}' @size='l' />
</div>
```
