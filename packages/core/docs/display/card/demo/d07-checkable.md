---
order: 7
---

# Checkable

<EuiText>
<p><strong>EuiCheckableCard</strong> wraps an <strong>EuiRadio</strong> or <strong>EuiCheckbox</strong> with a more-prominent panel, allowing for children to be displayed.</p>
</EuiText>

```hbs template
{{#let (use-state false) as |checkState|}}
  <EuiFlexGroup>
    <EuiFlexItem>
      <EuiCheckableCard
        @checkableType='checkbox'
        @label='I am a checkbox'
        @checked={{checkState.value}}
        {{on 'change' (fn checkState.setState (not checkState.value))}}
      />
    </EuiFlexItem>
  </EuiFlexGroup>
{{/let}}
```
