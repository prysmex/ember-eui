---
order: 3
---

# Text wrapping and tooltips

 <EuiText>
   <p>Optional props <EuiCode>showToolTip</EuiCode> and <EuiCode>wrapLines</EuiCode> can be used to augment the display of list items. Use these when lists are inside small containers where it is likely that the content will be truncated.</p>
</EuiText>

```hbs template
<EuiListGroup @showToolTips>
  <EuiListGroupItem>
    First item
  </EuiListGroupItem>

  <EuiListGroupItem>
    Second item
  </EuiListGroupItem>

  <EuiListGroupItem>
    <span>
      Third very, very long item that
      <strong>will surely</strong>
      force truncation
    </span>
  </EuiListGroupItem>
  <EuiListGroupItem @wrapText={{true}}>Fourth very, very long item with wrapping
    enabled that will not force truncation</EuiListGroupItem>
</EuiListGroup>
```
