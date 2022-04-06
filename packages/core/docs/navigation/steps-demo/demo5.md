---
order: 3
---

# Heading elements

<EuiText>
<p>To aid with accessibility and hierarchical headings, you can and should pass in a heading element to use for each step title. The example below shows that the logical heading element should be an <EuiCode>h2</EuiCode>and therefore adds <EuiCode>headingElement<span class="token verb keyword">=</span><span class="token conjunction variable">"</span>h2<span class="token conjunction variable">"</span></EuiCode> to the EuiSteps component.</p>
<p>The style of the title will <strong>not</strong> be affected.</p>
</EuiText>

```hbs template
<div>
  <EuiTitle size='l'>
    <h1>Heading 1</h1>
  </EuiTitle>

  <EuiSpacer size='xl' />

  <EuiSteps @headingElement='h2'>
    <EuiStep @step={{1}} @title='Step 1'>
      <EuiTitle @size='xs'>
        <h3>Did you notice the step title is inside a Heading 2 element?</h3>
      </EuiTitle>
    </EuiStep>

  </EuiSteps>
</div>
```
