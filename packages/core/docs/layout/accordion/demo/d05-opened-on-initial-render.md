---
order: 5
---

# Opened on initial render

<EuiText>
  Use the
  <EuiCode>initialIsOpen</EuiCode>
  prop to open the accordion when first rendered.
</EuiText>

```hbs template
<EuiAccordion @initialIsOpen={{true}}>
  <:buttonContent>
    I am opened by default. Click me to toggle close / open
  </:buttonContent>
  <:content>
    <EuiPanel @color='subdued'>
      Any content inside of
      <strong>EuiAccordion</strong>
      will appear here.
    </EuiPanel>
  </:content>
</EuiAccordion>
```
