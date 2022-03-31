---
order: 4
---

# Title size

<EuiText>
<p>
<EuiCode>title</EuiCode> uses the <strong>EuiTitle</strong> component and thus uses the same sizing property values (applied via the <EuiCode>titleSize</EuiCode> property). Although all <strong>EuiTitle</strong> sizes are available, suggested sizes include <EuiCode @language='js'>'l' | 'm' | 's' | 'xs' | 'xxs' | 'xxxs'</EuiCode>. By default, the size is set to large <EuiCode>'l'</EuiCode>. The <EuiCode>description</EuiCode> label cannot be re-sized via component properties.
</p>
</EuiText>

```hbs template
<div>
  <EuiFlexGroup>
    <EuiFlexItem>
      <EuiStat @title='1,000,000' @description='Large size' @titleSize='l' />
    </EuiFlexItem>
    <EuiFlexItem>
      <EuiStat @title='1,000,000' @description='Medium size' @titleSize='m' />
    </EuiFlexItem>
    <EuiFlexItem>
      <EuiStat @title='1,000,000' @description='Small size' @titleSize='s' />
    </EuiFlexItem>
  </EuiFlexGroup>
  <EuiFlexGroup>
    <EuiFlexItem>
      <EuiStat
        @title='1,000,000'
        @description='Extra small size'
        @titleSize='xs'
      />
    </EuiFlexItem>
    <EuiFlexItem>
      <EuiStat
        @title='1,000,000'
        @description='Extra extra small size'
        @titleSize='xxs'
      />
    </EuiFlexItem>
    <EuiFlexItem>
      <EuiStat
        @title='1,000,000'
        @description='Extra extra extra small size'
        @titleSize='xxxs'
      />
    </EuiFlexItem>
  </EuiFlexGroup>
</div>
```
