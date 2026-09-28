---
order: 2
---

# Skip link

<EuiText>

Click in the box, then press <kbd>Tab</kbd>: the link appears. Pressing
<kbd>Enter</kbd> moves focus to the destination, which has
`tabindex="-1"` so it can receive focus. `@position="fixed"` shows it at
the top left of the viewport instead.

</EuiText>

```hbs template
<EuiPanel @color="subdued" tabindex="0">
  <EuiSkipLink @destinationId="skip-link-demo-target">
    Skip to the results
  </EuiSkipLink>
  <EuiText @size="s">
    <p>Filters, navigation and other content to skip…</p>
  </EuiText>
  <EuiSpacer />
  <EuiPanel id="skip-link-demo-target" tabindex="-1">
    <EuiText @size="s"><p>The results.</p></EuiText>
  </EuiPanel>
</EuiPanel>
```
