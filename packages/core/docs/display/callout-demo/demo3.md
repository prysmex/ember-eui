---
order: 3
---

# Warning

<EuiText>
  <p>
    Use this callout to warn the user against decisions they might regret.
  </p>
</EuiText>

```hbs template
<EuiCallOut
  @size='s'
  @title='Proceed with caution!'
  @iconType='pin'
  @color='warning'
>
  <:body>
    <p>
      Here be dragons. Don’t wanna mess with no dragons.
    </p>
    <EuiButton @color='warning'>
      Link button
    </EuiButton>
  </:body>
</EuiCallOut>
```
