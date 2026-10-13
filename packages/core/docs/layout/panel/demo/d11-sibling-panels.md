---
order: 11
---

# Sibling panels

<EuiText>
  <p>
When sibling panels have the same meaning and interaction, like cards, it is best to keep them all visually similar. On the other hand you can use panels to separate main from aside content. In this case, you will want to ensure visual prominence of the main content.
  </p>
</EuiText>

```hbs template
<EuiSpacer @size='l' />
<EuiFlexGroup @gutterSize='m'>
  <EuiFlexItem>
    <EuiText @size='s'><p><strong>Do:</strong> Use the same styles for cards in a row.</p></EuiText>
    <EuiSpacer @size='s' />
    <EuiPanel @hasShadow={{false}} @hasBorder={{true}} style='transform: scale(.9);'>
      <EuiTitle @size='s'><span>Panel 1</span></EuiTitle>
      <EuiSpacer />
      <EuiPanel @color='subdued'>
        <EuiTitle @size='xs'><span>Panel 2</span></EuiTitle>
        <EuiSpacer />
        <EuiFlexGroup @wrap={{true}}>
          <EuiFlexItem>
            <EuiCard @titleSize='xs' @layout='horizontal' @title='Card 1' @description='Cards are panels too.' />
          </EuiFlexItem>
          <EuiFlexItem>
            <EuiCard @titleSize='xs' @layout='horizontal' @title='Card 2' @description='Cards are panels too.' />
          </EuiFlexItem>
        </EuiFlexGroup>
      </EuiPanel>
    </EuiPanel>
  </EuiFlexItem>
  <EuiFlexItem>
    <EuiText @size='s'><p><strong>Do:</strong> Only emphasize the main content panel.</p></EuiText>
    <EuiSpacer @size='s' />
    <EuiPanel @color='subdued' @hasShadow={{false}} style='transform: scale(.9);'>
      <EuiTitle @size='s'><span>Panel 1</span></EuiTitle>
      <EuiSpacer />
      <EuiFlexGroup @responsive={{false}} @wrap={{true}}>
        <EuiFlexItem @grow={{2}}>
          <EuiPanel @hasShadow={{true}} @hasBorder={{false}} style='min-height: 170px;'>
            <EuiTitle @size='xs'><span>Main panel</span></EuiTitle>
          </EuiPanel>
        </EuiFlexItem>
        <EuiFlexItem>
          <EuiPanel @hasShadow={{false}} @hasBorder={{true}} @color='transparent' style='min-height: 170px;'>
            <EuiTitle @size='xs'><span>Aside panel</span></EuiTitle>
          </EuiPanel>
        </EuiFlexItem>
      </EuiFlexGroup>
    </EuiPanel>
  </EuiFlexItem>
</EuiFlexGroup>
```
