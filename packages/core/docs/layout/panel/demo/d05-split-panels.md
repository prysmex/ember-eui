---
order: 4
---

# Split panels

<EuiText>

A split panel is an outer panel made of inner sections, each with its own
color and padding. In `.gjs`/`.gts` import `EuiSplitPanelOuter` and
`EuiSplitPanelInner` from `@ember-eui/core/components`; in `.hbs`
templates they are `<EuiSplitPanel::Outer>` and `<EuiSplitPanel::Inner>`.

Sections stack (`@direction="column"`, the default) or sit side by side
(`@direction="row"`). A row layout stacks on small screens; pass the
screen sizes to stack on as `@responsive` (default `["xs", "s"]`) or
`false` to never stack.

</EuiText>

```hbs template
<EuiFlexGroup @gutterSize='l'>
  <EuiFlexItem>
    <EuiSplitPanel::Outer @grow={{true}}>
      <EuiSplitPanel::Inner>
        <EuiText>
          <p>Top panel</p>
        </EuiText>
      </EuiSplitPanel::Inner>
      <EuiSplitPanel::Inner @grow={{false}} @color='subdued'>
        <EuiText>
          <p>
            Bottom panel has
            <EuiCode>{'grow={false}'}</EuiCode>
          </p>
        </EuiText>
      </EuiSplitPanel::Inner>
    </EuiSplitPanel::Outer>
  </EuiFlexItem>
  <EuiFlexItem>
    <EuiSplitPanel::Outer @grow={{false}}>
      <EuiSplitPanel::Inner>
        <EuiText>
          <p>
            Outer panel has
            <EuiCode>{'grow={false}'}</EuiCode>
          </p>
        </EuiText>
      </EuiSplitPanel::Inner>
      <EuiSplitPanel::Inner @grow={{false}} @color='subdued'>
        <EuiText>
          <p>Bottom panel</p>
        </EuiText>
      </EuiSplitPanel::Inner>
    </EuiSplitPanel::Outer>
  </EuiFlexItem>
  <EuiFlexItem>
    <EuiSplitPanel::Outer>
      <EuiSplitPanel::Inner>
        <EuiText>
          <p>Top panel</p>
        </EuiText>
      </EuiSplitPanel::Inner>
      <EuiSplitPanel::Inner @color='subdued'>
        <EuiText>
          <p>Middle panel</p>
        </EuiText>
      </EuiSplitPanel::Inner>
      <EuiSplitPanel::Inner @color='danger'>
        <EuiText>
          <p>Danger panel</p>
        </EuiText>
      </EuiSplitPanel::Inner>
    </EuiSplitPanel::Outer>
  </EuiFlexItem>
</EuiFlexGroup>
<EuiSpacer />
<EuiSplitPanel::Outer @direction='row'>
  <EuiSplitPanel::Inner>
    <EuiText>
      <p>Left panel</p>
      <p>Has more content</p>
    </EuiText>
  </EuiSplitPanel::Inner>
  <EuiSplitPanel::Inner @color='subdued'>
    <EuiText>
      <p>Right panel</p>
    </EuiText>
  </EuiSplitPanel::Inner>
</EuiSplitPanel::Outer>
```
