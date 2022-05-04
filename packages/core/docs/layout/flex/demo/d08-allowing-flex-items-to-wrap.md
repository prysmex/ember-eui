---
order: 8
---

# Allowing flex items to wrap


```hbs template
<EuiFlexGroup class="flex-demo" @wrap={{true}}>
  <EuiFlexItem style="min-width: 300">Min-width 300px</EuiFlexItem>

  <EuiFlexItem style="min-width: 300">Min-width 300px</EuiFlexItem>

  <EuiFlexItem style="min-width: 300">Min-width 300px</EuiFlexItem>
</EuiFlexGroup>

<EuiHorizontalRule/>

<EuiFlexGroup class="flex-demo" @justifyContent="spaceBetween">
  <EuiFlexItem @grow={{false}}>One here on the left.</EuiFlexItem>
  <EuiFlexItem @grow={{false}}>The other over here on the right.</EuiFlexItem>
</EuiFlexGroup>

<EuiHorizontalRule/>

<EuiFlexGroup class="flex-demo" @justifyContent="spaceEvenly">
  <EuiFlexItem @grow={{false}}>Spaced evenly between this one.</EuiFlexItem>
  <EuiFlexItem @grow={{false}}>And this one here on the right.</EuiFlexItem>
</EuiFlexGroup>

<EuiHorizontalRule/>

<EuiFlexGroup class="flex-demo" @alignItems="center">
  <EuiFlexItem @grow={{false}}>
    <p>I</p>
    <p>am</p>
    <p>a</p>
    <p>tall</p>
    <p>item</p>
  </EuiFlexItem>
  <EuiFlexItem>I am vertically centered!</EuiFlexItem>
</EuiFlexGroup>
```