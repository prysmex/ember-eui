---
order: 5
---

# Loading and error prompts

<EuiText>
 Empty prompts can also be used to emulate loading and error states, by utilizing the same patterns.
 For <strong>loading</strong> states, instead of passing a <EuiCode>iconType</EuiCode>, you can provide a custom <EuiCode>icon</EuiCode> and pass in one of our loading components.
</EuiText>

```hbs template
<EuiEmptyPrompt @title='Loading Dashboards'>
  <:icon>
    <EuiLoadingLogo @logo='logoKibana' @size='xl' />
  </:icon>
</EuiEmptyPrompt>
<EuiSpacer @size='l' />
<EuiText>
  For error states, you can simply set the
  <EuiCode>color</EuiCode>
  to
  <EuiCode>danger</EuiCode>.
</EuiText>
<EuiSpacer />
<EuiEmptyPrompt
  @iconType='alert'
  @color='danger'
  @title='Error loading Dashboards'
  @body='There was an error loading the Dashboard application. Contact your
        administrator for help.'
/>
```
