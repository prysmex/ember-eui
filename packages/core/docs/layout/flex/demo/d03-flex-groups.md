---
order: 3
---

# Flex groups

<EuiText>

`EuiFlexGroup` is useful for setting up layouts for a single row of content. By default, any `EuiFlexItem` within `EuiFlexGroup` will stretch and grow to match their siblings.

</EuiText>

```hbs template
<EuiFlexGroup class="flex-demo">
  <EuiFlexItem>Flex item</EuiFlexItem>
  <EuiFlexItem>
    <p>Another flex item</p>
    <EuiSpacer />
    <p>
      Note how both of these are the same width and height despite having
      different content?
    </p>
  </EuiFlexItem>
</EuiFlexGroup>
```
