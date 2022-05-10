---
order: 1
---

<EuiText>
  The <EuiCode>EuiSpacer</EuiCode> component is for adding vertical space between items and should be used in place of the <EuiCode><br/></EuiCode> tag. There are many different heights you can specify via the size prop which align to the EUI vertical grid sizing.
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