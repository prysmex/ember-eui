---
order: 3
---

# Beta item

<EuiText>

If the item links to a module that is not GA (beta, lab, etc), you can add a `@betaBadgeLabel` and `@betaBadgeTooltipContent` to the item and it will properly create and position an **EuiBetaBadge**.

Supplying just a label will only show the first letter in the badge but displays the full label to the tooltip. You can also pass a `@betaBadgeIconType` to replace the letter.

</EuiText>

<EuiSpacer />

```gjs component
import { EuiIcon, EuiKeyPadMenu, EuiKeyPadMenuItem } from '@ember-eui/core/components';

<template>
<EuiKeyPadMenu as |Key|>
  <Key>
    <EuiKeyPadMenuItem @label="No beta">
      <EuiIcon @type="textStrike" @size="l" />
    </EuiKeyPadMenuItem>
  </Key>

  <Key>
    <EuiKeyPadMenuItem
      @label="Icon"
      @betaBadgeLabel="Beta"
      @betaBadgeTooltipContent="This module is not GA. Please help us by reporting any bugs."
      @betaBadgeIconType="beta"
    >
      <EuiIcon @type="textBold" @size="l" />
    </EuiKeyPadMenuItem>
  </Key>

  <Key>
    <EuiKeyPadMenuItem
      @label="Icon"
      @betaBadgeLabel="External"
      @betaBadgeTooltipContent="This module is an external app."
      @betaBadgeIconType="external"
    >
      <EuiIcon @type="code" @size="l" />
    </EuiKeyPadMenuItem>
  </Key>
</EuiKeyPadMenu>
</template>
```
