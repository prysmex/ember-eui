---
order: 1
---

# Screen reader only

<EuiText>

The second sentence is read by screen readers but not shown. Select the
text around it to see it is there.

</EuiText>

```hbs template
<EuiText>
  <p>
    This paragraph is visible to everyone.
    <EuiScreenReaderOnly>
      This sentence is only for screen reader users.
    </EuiScreenReaderOnly>
    So is this one.
  </p>
</EuiText>
```
