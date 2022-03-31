---
order: 4
---

# Danger

<EuiText>
  <p>
    Use this callout to let the user know that something went wrong.
  </p>
</EuiText>

```hbs template
<EuiCallOut
  @size='s'
  @title='Sorry, there was an error'
  @iconType='pin'
  @color='danger'
>
  <:body>
    <p>
      Now you have to fix it, but maybe this link can help.
    </p>
  </:body>
</EuiCallOut>
```
