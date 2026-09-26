---
order: 1
---

# Steps

```hbs template
<EuiSteps>
  <EuiStep @step={{1}} @title='Step 1'>
    Do this first
  </EuiStep>
  <EuiStep @step={{2}} @title='Step 2'>
    Then this
  </EuiStep>
</EuiSteps>
<EuiSpacer @size='m' />
<EuiText>
  <p>
    Set
    <EuiCode>firstStepNumber</EuiCode>
    to continue step numbering after any type of break in the content
  </p>
</EuiText>
<EuiSpacer @size='m' />
```
