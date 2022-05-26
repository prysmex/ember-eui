---
order: 4
---

# Title sizes and icon colors

<EuiText>
 Other customization options include changing the <EuiCode>titleSize</EuiCode> to any of the <strong>EuiTitle</strong> sizes and <EuiCode>iconColor</EuiCode>. When using an application or solution logo as the <EuiCode>iconType</EuiCode>, you can reset to the multi-tone colors with <EuiCode>iconColor="default"</EuiCode>
</EuiText>

```hbs template
<EuiEmptyPrompt
  @iconType='securityAnalyticsApp'
  @iconColor='default'
  @title='Start adding cases'
  @titleSize='xs'
  @body='There are no cases to display. Add a new case or change your filter
          settings.'
  @actions={{array (component 'eui-button-title' title='Add a case')}}
/>
```
