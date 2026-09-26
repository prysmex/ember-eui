---
order: 3
---

# Text wrapping

<EuiText>

Long item labels are truncated to one line by default. `@wrapText={{true}}`
on an item wraps its text instead, for lists inside narrow containers.

</EuiText>

```hbs template
<EuiListGroup>
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
