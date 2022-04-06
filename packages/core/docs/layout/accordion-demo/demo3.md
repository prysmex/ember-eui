---
order: 3
---

# Extra actions

<EuiText>
  Use the <EuiCode>extraAction</EuiCode> prop to pass an extra action displayed on the right of any accordion. Usually this is a delete or button, but can be anything. Note that this action is separate from the click state that expands the accordion. This is needed to make it accessible.
</EuiText>

```hbs template
<EuiAccordion @paddingSize='m' @extraAction={{true}}>
  <:buttonContent>
    Click to open
  </:buttonContent>
  <:content>
    <EuiText size='s'>
      <strong>Opened content </strong>
    </EuiText>
  </:content>
  <:extraAction>
    <EuiButton @size='s'>Extra action!</EuiButton>
  </:extraAction>
</EuiAccordion>
```
