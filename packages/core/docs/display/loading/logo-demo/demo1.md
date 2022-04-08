# Basic loading logo

<EuiText>
 <strong>EuiLoadingLogo</strong> accepts any of our <strong>EuiIcon</strong> logos. It should only be used in very large panels, like full screen pages.
</EuiText>

```hbs template
<div>
  <EuiLoadingLogo />
  &emsp;
  <EuiLoadingLogo @logo='logoObservability' @size='l' />
  &emsp;
  <EuiLoadingLogo @logo='logoSecurity' @size='xl' />
</div>
```
