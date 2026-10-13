---
order: 7
---

# Flush argument

<EuiText>

The `@flush` argument is only available for `EuiButtonEmpty`. It removes padding, ensuring stricter alignment with surrounding content, especially at container edges where empty buttons might otherwise create a ragged line.

</EuiText>

```hbs template
<EuiFlexGroup @gutterSize="s" @direction="row">
  <EuiFlexItem style="width: 240px" @grow={{false}}>
    <EuiPanel @color="plain" @hasBorder={{true}}>
      <EuiTitle @size="xs"><h4>Title of panel</h4></EuiTitle>
      <EuiHorizontalRule />
      <EuiButtonEmpty @flush="left">Flush left</EuiButtonEmpty>
    </EuiPanel>
  </EuiFlexItem>
  <EuiFlexItem style="width: 240px" @grow={{false}}>
    <EuiPanel style="text-align: right" @color="plain" @hasBorder={{true}} @grow={{false}}>
      <EuiButton @size="s">Button</EuiButton>
      <EuiHorizontalRule />
      <EuiButtonEmpty @flush="right">Flush right</EuiButtonEmpty>
    </EuiPanel>
  </EuiFlexItem>
</EuiFlexGroup>
```
