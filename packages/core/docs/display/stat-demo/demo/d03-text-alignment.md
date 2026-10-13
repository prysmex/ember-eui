---
order: 3
---

# Text alignment

<EuiText>

**EuiStat** also offers alignment options. By default, text will be left aligned.

</EuiText>

```hbs template
<div>
  <EuiFlexGroup>
    <EuiFlexItem>
      <EuiStat @title="$ 1,000.00" @description="Left align" @textAlign="left" />
    </EuiFlexItem>
    <EuiFlexItem>
      <EuiStat @title="99.9999" @description="Center align" @textAlign="center" />
    </EuiFlexItem>
    <EuiFlexItem>
      <EuiStat @title="1,000.00 €" @description="Right align" @textAlign="right" />
    </EuiFlexItem>
  </EuiFlexGroup>
</div>
```
