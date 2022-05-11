---
order: 7
---

# Loading state


```hbs template
<EuiFlexGroup @responsive={{false}} @wrap={{true}} @gutterSize="s" @alignItems="center">
  <EuiFlexItem @grow={{false}}>
    <EuiButton @isLoading={true}>Loading&hellip;</EuiButton>
  </EuiFlexItem>

  <EuiFlexItem @grow={{false}}>
    <EuiButton @fill={{true}} @size="s" @isLoading={true}>
      Loading&hellip;
    </EuiButton>
  </EuiFlexItem>

  <EuiFlexItem @grow={{false}}>
    <EuiButton @fill={{true}} @isLoading={true} @iconType="check" @iconSide="right">
      Loading&hellip;
    </EuiButton>
  </EuiFlexItem>

  <EuiFlexItem @grow={{false}}>
    <EuiButtonEmpty @isLoading={{true}}>
      Loading&hellip;
    </EuiButtonEmpty>
  </EuiFlexItem>

  <EuiFlexItem @grow={{false}}>
    <EuiButtonEmpty @size="xs" @isLoading={{true}} @iconSide="right">
      Loading&hellip;
    </EuiButtonEmpty>
  </EuiFlexItem>
</EuiFlexGroup>
```