---
order: 10
---

# Anchor props

<EuiText>

`@anchorProps` (upstream `anchorProps`) customizes the `span` wrapping the
anchor: `className`, `css`, `style` (an object of CSS properties), `on<Event>`
listeners and any attribute such as `data-test-subj`. `EuiIconTip` and
`EuiBetaBadge` take it too.

</EuiText>

```gjs component
import { hash } from '@ember/helper';
import {
  EuiBetaBadge,
  EuiButton,
  EuiFlexGroup,
  EuiFlexItem,
  EuiIconTip,
  EuiToolTip
} from '@ember-eui/core/components';

<template>
  <EuiFlexGroup @alignItems="center" @gutterSize="l" @responsive={{false}}>
    <EuiFlexItem @grow={{false}}>
      <EuiToolTip
        @content="The anchor wrapper has its own test subject and padding"
        @anchorProps={{hash
          data-test-subj="tooltipAnchor"
          style=(hash padding=4)
        }}
      >
        <EuiButton>Hover me</EuiButton>
      </EuiToolTip>
    </EuiFlexItem>
    <EuiFlexItem @grow={{false}}>
      <EuiIconTip
        @content="Shown 40px away from the icon"
        @position="bottom"
        @offset={{40}}
        @anchorProps={{hash data-test-subj="iconTipAnchor"}}
      />
    </EuiFlexItem>
    <EuiFlexItem @grow={{false}}>
      <EuiBetaBadge
        @label="Beta"
        @tooltipContent="This module is not GA."
        @anchorProps={{hash data-test-subj="betaBadgeAnchor"}}
      />
    </EuiFlexItem>
  </EuiFlexGroup>
</template>
```
