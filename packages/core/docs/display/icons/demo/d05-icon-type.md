---
order: 5
---

# Icons in other components

<EuiText>

Many components take an `@iconType` and render the `EuiIcon` for you, with the
right size and color for that component. `@iconType` accepts everything
`@type` does: an EUI icon name, a registered name, a component or a URL.

A few of them: `EuiButton`, `EuiButtonEmpty`, `EuiButtonIcon`,
`EuiButtonGroup` options, `EuiBadge`, `EuiBetaBadge`, `EuiCallOut`,
`EuiEmptyPrompt`, `EuiListGroupItem`, `EuiKeyPadMenuItem`, `EuiToast`,
`EuiAvatar`, `EuiHeaderLogo` and `EuiPageHeader`.

</EuiText>

```hbs template
<EuiFlexGroup @gutterSize="s" @alignItems="center" @wrap={{true}}>
  <EuiFlexItem @grow={{false}}>
    <EuiButton @iconType="plusInCircle">Add data</EuiButton>
  </EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    <EuiButtonEmpty @iconType="arrowDown" @iconSide="right">
      More
    </EuiButtonEmpty>
  </EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    <EuiButtonIcon @iconType="gear" aria-label="Settings" />
  </EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    <EuiBadge @iconType="clock" @color="hollow">5 minutes ago</EuiBadge>
  </EuiFlexItem>
</EuiFlexGroup>

<EuiSpacer />

<EuiCallOut @title="Heads up" @iconType="help">
  <p>Callouts, list items, toasts and empty prompts take an icon too.</p>
</EuiCallOut>
```
