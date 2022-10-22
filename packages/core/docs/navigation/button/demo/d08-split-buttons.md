---
order: 8
---

# Split buttons

<EuiText>
<p>EUI split buttons specifically. Instead, we recommend using separate buttons for the main and overflow actions. You can achieve this by simply using the <EuiCode>display</EuiCode> and <EuiCode>size</EuiCode> args <strong>EuiButtonIcon</strong> to match that of the primary action button.</p>
</EuiText>

```hbs template
<EuiFlexGroup @responsive={{false}} @gutterSize='xs' @alignItems='center'>
  <EuiFlexItem @grow={{false}}>
    <EuiButton @size='s' @iconType='calendar'>
      Last 15 min
    </EuiButton>
  </EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    <EuiButtonIcon @iconType='boxesVertical' @display='base' @size='s' />
  </EuiFlexItem>
</EuiFlexGroup>
```
