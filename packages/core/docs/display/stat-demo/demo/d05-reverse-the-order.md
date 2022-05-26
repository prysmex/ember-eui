---
order: 5
---

# Reverse the order

<EuiText>
<p>
You can reverse the order of the <EuiCode>description</EuiCode> and <EuiCode>title</EuiCode> text by setting the <EuiCode>reverse</EuiCode> property to true. By default, the description (label) is displayed above the title (value).
</p>
</EuiText>

```hbs template
<div>
  <EuiFlexGroup>
    <EuiFlexItem>
      <EuiStat
        @title='10,000'
        @description='Description underneath'
        @reverse={{true}}
      />
    </EuiFlexItem>
  </EuiFlexGroup>
</div>
```
