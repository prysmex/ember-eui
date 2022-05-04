---
order: 5
---

# Turn off item stretching

```hbs template
<EuiFlexGroup class="flex-demo">
  <EuiFlexItem @grow={{false}}>This item won&rsquo;t grow</EuiFlexItem>
  <EuiFlexItem>But this item will.</EuiFlexItem>
</EuiFlexGroup>
```