---
order: 3
---

# Flush empty button


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