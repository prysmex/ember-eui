---
order: 7
---

# Justify and align

<EuiText>

`@justifyContent` distributes the items along the row (`flexStart`, `center`, `flexEnd`, `spaceBetween`, `spaceAround`, `spaceEvenly`) and `@alignItems` aligns them across it (`stretch`, `flexStart`, `center`, `flexEnd`, `baseline`).

</EuiText>

```hbs template
  <EuiFlexGroup class="flex-demo" @justifyContent="spaceAround">
    <EuiFlexItem @grow={{false}}>I&rsquo;m a single centered item!</EuiFlexItem>
  </EuiFlexGroup>
```