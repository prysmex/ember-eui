---
order: 5
---

```hbs template
<EuiTitle>
  Opened on initial render
</EuiTitle>
<EuiSpacer />
<EuiText>
  Use the
  <EuiCode>initialIsOpen</EuiCode>
  prop to open the accordion when first rendered.
</EuiText>
<EuiSpacer />
<EuiAccordion @paddingSize='m' @initialIsOpen={{true}}>
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