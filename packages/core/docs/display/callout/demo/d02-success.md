---
order: 2
---

# Success

<EuiText>
  <p>
    Use this callout to notify the user of an action that succesfully completed.
    Use success callouts sparingly—callouts are typically used for things that
    are broken rather than things that succeed.
  </p>
</EuiText>

```hbs template
<EuiCallOut
  @size='s'
  @title='This is a small callout for more unintrusive but constant messages.'
  @iconType='pin'
  @color='success'
>
  <:body>
    <p>
      I have no news. Which is good!
    </p>
  </:body>
</EuiCallOut>
```
