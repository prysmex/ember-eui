---
order: 2
---

# List of links

 <EuiText>
   <p>Display <strong>EuiListGroupItems</strong> as links by providing an <EuiCode>href</EuiCode> value and change their state with the <EuiCode>isActive</EuiCode> and <EuiCode>isDisabled</EuiCode> properties.</p><p>As is done in this example, the <strong>EuiListGroup</strong> component can also accept an array of items via the <EuiCode>listItems</EuiCode> property.</p>
</EuiText>

```hbs template
<EuiListGroup>
  <EuiListGroupItem @href='#/display/list-group' @iconType='calendar' @size='s'>
    First link
  </EuiListGroupItem>
  <EuiListGroupItem
    @href='#/display/list-group'
    @iconType='clock'
    @size='s'
    @isActive='true'
  >
    This is an active link with very long label that truncates
  </EuiListGroupItem>
  <EuiListGroupItem
    @href='#/display/list-group'
    @iconType='compute'
    @size='s'
    @isDisabled='true'
  >
    Third link is disabled
  </EuiListGroupItem>
  <EuiListGroupItem
    @href='#/display/list-group'
    @iconType='copyClipboard'
    @size='s'
  >
    Fourth link
  </EuiListGroupItem>
  <EuiListGroupItem
    @href='#/display/list-group'
    @iconType='crosshairs'
    @size='s'
  >
    Fifth link
  </EuiListGroupItem>
</EuiListGroup>
```
