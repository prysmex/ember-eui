---
order: 3
---

# Flush empty button

<EuiText>

`@flush` removes an empty button's padding on the `left`, `right` or `both`
sides, so its text lines up with content above or below it.

</EuiText>

```hbs template
  <EuiFlexGroup
    @responsive={{false}}
    @gutterSize="s"
    @alignItems="center"
  >
    <EuiFlexItem @grow={{false}}>
      <EuiButtonEmpty @flush="left">
        Flush left
      </EuiButtonEmpty>
    </EuiFlexItem>

    <EuiFlexItem @grow={{false}}>
      <EuiButtonEmpty @flush="right">
        Flush right
      </EuiButtonEmpty>
    </EuiFlexItem>

    <EuiFlexItem @grow={{false}}>
      <EuiButtonEmpty @flush="both">
        Flush both
      </EuiButtonEmpty>
    </EuiFlexItem>
  </EuiFlexGroup>
```