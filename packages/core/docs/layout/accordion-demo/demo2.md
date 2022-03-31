---
order: 2
---

```hbs template
<EuiTitle>
  Arrow display
</EuiTitle>
<EuiSpacer />
<EuiText>
  The arrow helps indicate the current state of the accordion (open or not) and points to the main triggering button text. If you must hide or change the side in which the arrow appears, use <EuiCode>arrowDisplay: 'right'</EuiCode> or <EuiCode>'none'</EuiCode>
</EuiText>
<EuiSpacer />
<EuiAccordion @arrowDisplay='right'>
  <:buttonContent>
    This accordion has the arrow on the right
  </:buttonContent>
  <:content>
    Any content inside of <strong>EuiAccordion</strong> will appear here.
  </:content>
</EuiAccordion>
<EuiSpacer />
<EuiAccordion @arrowDisplay='none'>
  <:buttonContent>
    This one has it removed entirely
  </:buttonContent>
  <:content>
    Any content inside of <strong>EuiAccordion</strong> will appear here.
  </:content>
</EuiAccordion>
```
