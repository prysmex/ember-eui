---
order: 2
---

# Split

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

```gjs component
import { EuiCode, EuiFlexGroup, EuiFlexItem, EuiSpacer, EuiSplitPanelInner, EuiSplitPanelOuter, EuiText } from '@ember-eui/core/components';

<template>
  <EuiFlexGroup @gutterSize='l'>
    <EuiFlexItem>
      <EuiSplitPanelOuter @grow={{true}}>
        <EuiSplitPanelInner>
          <EuiText>
            <p>Top panel</p>
          </EuiText>
        </EuiSplitPanelInner>
        <EuiSplitPanelInner @grow={{false}} @color='subdued'>
          <EuiText>
            <p>
              Bottom panel has
              <EuiCode>@grow=\{{false}}</EuiCode>
            </p>
          </EuiText>
        </EuiSplitPanelInner>
      </EuiSplitPanelOuter>
    </EuiFlexItem>
    <EuiFlexItem>
      <EuiSplitPanelOuter @grow={{false}}>
        <EuiSplitPanelInner>
          <EuiText>
            <p>
              Outer panel has
              <EuiCode>@grow=\{{false}}</EuiCode>
            </p>
          </EuiText>
        </EuiSplitPanelInner>
        <EuiSplitPanelInner @grow={{false}} @color='subdued'>
          <EuiText>
            <p>Bottom panel</p>
          </EuiText>
        </EuiSplitPanelInner>
      </EuiSplitPanelOuter>
    </EuiFlexItem>
    <EuiFlexItem>
      <EuiSplitPanelOuter>
        <EuiSplitPanelInner>
          <EuiText>
            <p>Top panel</p>
          </EuiText>
        </EuiSplitPanelInner>
        <EuiSplitPanelInner @color='subdued'>
          <EuiText>
            <p>Middle panel</p>
          </EuiText>
        </EuiSplitPanelInner>
        <EuiSplitPanelInner @color='danger'>
          <EuiText>
            <p>Danger panel</p>
          </EuiText>
        </EuiSplitPanelInner>
      </EuiSplitPanelOuter>
    </EuiFlexItem>
  </EuiFlexGroup>
  <EuiSpacer />
  <EuiSplitPanelOuter @direction='row'>
    <EuiSplitPanelInner>
      <EuiText>
        <p>Left panel</p>
        <p>Has more content</p>
      </EuiText>
    </EuiSplitPanelInner>
    <EuiSplitPanelInner @color='subdued'>
      <EuiText>
        <p>Right panel</p>
      </EuiText>
    </EuiSplitPanelInner>
  </EuiSplitPanelOuter>
</template>
```
