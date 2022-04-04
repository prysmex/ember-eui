---
order: 2
---

# Shadow and border

<EuiText>
  <p>
<strong>EuiPanel</strong> can give depth to your container with <EuiCode>hasShadow</EuiCode> while <EuiCode>hasBorder</EuiCode> can add containment. Just be sure not to include too many nested panels with these settings.
  </p>
</EuiText>

```hbs template
<EuiSpacer @size='l' />
<EuiPanel @hasShadow={{false}}>
  @hasShadow={{false}}
</EuiPanel>
<EuiSpacer @size='l' />
<EuiPanel @hasBorder={{true}}>
  @hasBorder={{true}}
</EuiPanel>
```
