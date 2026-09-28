---
order: 2
---

# Size, shape, fill and color

<EuiText>

`@size` is `'xs'` to `'l'`. `@shape`, `@fill` (`'light'`, `'dark'`,
`'none'`) and `@color` (`'euiColorVis0'` to `'euiColorVis9'`, `'gray'` or a
hex color) change the look, also of the preset `token*` icons.

</EuiText>

```hbs template
<EuiFlexGroup @alignItems="center" @gutterSize="m" @responsive={{false}} @wrap={{true}}>
  <EuiFlexItem @grow={{false}}><EuiToken @iconType="tokenDate" @size="xs" /></EuiFlexItem>
  <EuiFlexItem @grow={{false}}><EuiToken @iconType="tokenDate" @size="s" /></EuiFlexItem>
  <EuiFlexItem @grow={{false}}><EuiToken @iconType="tokenDate" @size="m" /></EuiFlexItem>
  <EuiFlexItem @grow={{false}}><EuiToken @iconType="tokenDate" @size="l" /></EuiFlexItem>
  <EuiFlexItem @grow={{false}}><EuiToken @iconType="tokenDate" @size="l" @shape="circle" @fill="dark" /></EuiFlexItem>
  <EuiFlexItem @grow={{false}}><EuiToken @iconType="tokenDate" @size="l" @fill="none" /></EuiFlexItem>
  <EuiFlexItem @grow={{false}}><EuiToken @iconType="bolt" @size="l" @color="euiColorVis3" @shape="square" /></EuiFlexItem>
  <EuiFlexItem @grow={{false}}><EuiToken @iconType="heart" @size="l" @color="#FF0000" /></EuiFlexItem>
</EuiFlexGroup>
```
