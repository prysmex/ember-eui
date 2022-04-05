---
order: 1
---

# Checkable

<EuiText>
<p><strong>EuiCheckableCard</strong> wraps an <strong>EuiRadio</strong> or <strong>EuiCheckbox</strong> with a more-prominent panel, allowing for children to be displayed.</p>
</EuiText>

```hbs template
<EuiFlexGroup>
  <EuiFlexItem>
    <EuiCheckableCard
      @checkableType='checkbox'
      @label='I am a checkbox'
      @checked={{true}}
    />
  </EuiFlexItem>
</EuiFlexGroup>
```
