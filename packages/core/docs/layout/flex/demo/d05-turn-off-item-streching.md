---
order: 5
---

# Turn off item stretching

<EuiText>

`@grow={{false}}` sizes an item to its content; the other items share the rest.

</EuiText>

```hbs template
<EuiFlexGroup class="flex-demo">
  <EuiFlexItem @grow={{false}}>This item won&rsquo;t grow</EuiFlexItem>
  <EuiFlexItem>But this item will.</EuiFlexItem>
</EuiFlexGroup>
```