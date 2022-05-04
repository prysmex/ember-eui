---
order: 1
---

# Simple and unstyled

<EuiText>
  <strong>EuiAccordion</strong>
  has been purposely designed with minimal styles, allowing you to visually
  enhance it as needed (see the accordion form example). The only styling
  enforced by EUI is the caret icon, which indicates to users that the item can
  be opened.
  A
  <EuiCode>buttonContent</EuiCode>
  prop defines the content of the clickable area. On click it will expose the
  children and animate based on the height of those children.<br /><br />
  For styling needs, classes can be individually applied with
  <EuiCode>className</EuiCode>
  (for the entire accordion), and
  <EuiCode>buttonClassName</EuiCode>
  (for the clickable area).
</EuiText>

```hbs template
<EuiAccordion>
  <:buttonContent>
    Click me to toggle
  </:buttonContent>
  <:content>
    <EuiPanel @color="subdued" @hasShadow={{false}}>
      Any content inside of <strong>EuiAccordion</strong> will appear here.
    </EuiPanel>
  </:content>
</EuiAccordion>
```
