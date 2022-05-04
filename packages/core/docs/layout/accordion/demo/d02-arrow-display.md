---
order: 2
---

# Arrow display

<EuiText>
  The arrow helps indicate the current state of the accordion (open or not) and points to the main triggering button text.
  If you must hide or change the side in which the arrow appears, use <EuiCode>arrowDisplay: 'right'</EuiCode> or <EuiCode>'none'</EuiCode>
</EuiText>

```hbs template
<EuiAccordion @arrowDisplay='right'>
  <:buttonContent>
    This accordion has the arrow on the right
  </:buttonContent>
  <:content>
    <EuiPanel @color="subdued" @hasShadow={{false}}>
      Any content inside of <strong>EuiAccordion</strong> will appear here.
    </EuiPanel>
  </:content>
</EuiAccordion>
<EuiSpacer />
<EuiAccordion @arrowDisplay='none'>
  <:buttonContent>
    This one has it removed entirely
  </:buttonContent>
  <:content>
    <EuiPanel @color="subdued" @hasShadow={{false}}>
      Any content inside of <strong>EuiAccordion</strong> will appear here.
    </EuiPanel>
  </:content>
</EuiAccordion>
```
