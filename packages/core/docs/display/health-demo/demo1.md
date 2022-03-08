# Demo

```hbs template
<EuiPanel @color='subdued'>
  <EuiHealth @color='subdued'>
    Inactive
  </EuiHealth>
  <EuiSpacer />
  <EuiHealth @color='primary'>
    Active
  </EuiHealth>
  <EuiSpacer />
  <EuiHealth @color='success'>
    Healthy
  </EuiHealth>
  <EuiSpacer />
  <EuiHealth @color='warning'>
    Warning
  </EuiHealth>
  <EuiSpacer />
  <EuiHealth @color='danger'>
    Failure
  </EuiHealth>
  <EuiSpacer />
  <EuiHealth @color='#000000'>
    Custom color as hex
  </EuiHealth>
  <EuiSpacer />
  <EuiHealth>
    No color
  </EuiHealth>
</EuiPanel>
<EuiSpacer />
<EuiTitle @size='m'>
  Initials
</EuiTitle>
<EuiSpacer />
<EuiPanel @color='subdued'>
  <EuiHealth @color='subdued' @textSize='xs'>
    Inactive
  </EuiHealth>
  <EuiSpacer />
  <EuiHealth @color='primary' @textSize='s'>
    Active
  </EuiHealth>
  <EuiSpacer />
  <EuiHealth @color='success' @textSize='m'>
    Healthy
  </EuiHealth>
  <EuiSpacer />
  <EuiTitle @size='s'>
    <h3>
      <EuiHealth @color='warning' @textSize='inherit'>
        Warning
      </EuiHealth>
    </h3>
  </EuiTitle>

</EuiPanel>
<EuiSpacer />
```
