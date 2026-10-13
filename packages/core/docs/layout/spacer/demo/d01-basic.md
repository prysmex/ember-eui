---
order: 1
---

# Sizes

<EuiText>

The `EuiSpacer` component is for adding vertical space between items and should be used in place of the `<br />` tag. There are many different heights you can specify via the `@size` arg which align to the EUI vertical grid sizing.

The default size is `l` (24px); upstream EUI defaults to `m` (16px), so pass `@size="m"` to match it.

</EuiText>

```hbs template
<div class="guideDemo__highlightSpacer">
  <EuiFlexGroup>
    <EuiFlexItem>
      <EuiCode>xs</EuiCode>
      <EuiSpacer @size="xs" />
    </EuiFlexItem>

    <EuiFlexItem>
      <EuiCode>s</EuiCode>
      <EuiSpacer @size="s" />
    </EuiFlexItem>

    <EuiFlexItem>
      <EuiCode>m</EuiCode>
      <EuiSpacer @size="m" />
    </EuiFlexItem>

    <EuiFlexItem>
      <EuiCode>l (default)</EuiCode>
      <EuiSpacer />
    </EuiFlexItem>

    <EuiFlexItem>
      <EuiCode>xl</EuiCode>
      <EuiSpacer @size="xl" />
    </EuiFlexItem>

    <EuiFlexItem>
      <EuiCode>xxl</EuiCode>
      <EuiSpacer @size="xxl" />
    </EuiFlexItem>
  </EuiFlexGroup>
</div>
```