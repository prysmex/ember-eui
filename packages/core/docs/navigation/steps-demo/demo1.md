---
order: 1
---

<EuiText>
<p><strong>EuiSteps</strong> presents procedural content in a numbered outline format. It is best used when presenting instructional content that must be conducted in a particular order. It requires a <EuiCode>title</EuiCode> and <EuiCode>children</EuiCode> to be present and will automatically increment the step number based on the initial <EuiCode>firstStepNumber</EuiCode>.</p>
</EuiText>

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
