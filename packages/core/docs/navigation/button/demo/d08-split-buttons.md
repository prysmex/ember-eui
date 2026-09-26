---
order: 8
---

# Split buttons

<EuiText>

EUI has no split button component. Put the main action and an
`EuiButtonIcon` for the other actions side by side, with the same
`@display` and `@size` so they read as one control; the icon button
usually opens a popover with more actions.

</EuiText>

```hbs template
<EuiFlexGroup @responsive={{false}} @gutterSize='xs' @alignItems='center'>
  <EuiFlexItem @grow={{false}}>
    <EuiButton @size='s' @iconType='calendar'>
      Last 15 min
    </EuiButton>
  </EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    <EuiButtonIcon
      @iconType='boxesVertical'
      @display='base'
      @size='s'
      aria-label='More time ranges'
    />
  </EuiFlexItem>
</EuiFlexGroup>
```
