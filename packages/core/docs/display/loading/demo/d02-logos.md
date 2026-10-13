---
order: 2
---

# Logos

<EuiText>

**EuiLoadingLogo** accepts any of our [EuiIcon](/docs/display/icons) logos. It should only be used in very large panels, like fullscreen pages.

</EuiText>

```hbs template
<div>
  <EuiLoadingLogo />
  &emsp;
  <EuiLoadingLogo @logo="logoObservability" @size="l" />
  &emsp;
  <EuiLoadingLogo @logo="logoSecurity" @size="xl" />
</div>
```
