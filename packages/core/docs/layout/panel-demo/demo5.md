---
order: 4
---

# Split panel

<EuiText>
 <p><strong>EuiSplitPanel</strong> is a composition of an outer and multiple inner <strong>EuiPanels</strong>. It is a namespaced component that you consume using <EuiCode>EuiSplitPanel.Outer</EuiCode> and <EuiCode>EuiSplitPanel.Inner</EuiCode> respectively. You can supply the same panel props to both components with the exception of a few to ensure the visual layout is correct. It also has two directions, <EuiCode>column</EuiCode> (default) and <EuiCode>row</EuiCode>.</p><p>For custom responsiveness, you can adjust at which breakpoints a <EuiCode>row</EuiCode> layout will stack by passing a new array of breakpoint names <EuiCode>['xs', 's']</EuiCode> to the <EuiCode>responsive</EuiCode> prop, or completely turn it off with <EuiCode>false</EuiCode>.</p>
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
