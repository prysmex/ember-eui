---
order: 1
---

# Key pad menu

<EuiText>

The **EuiKeyPadMenu** component presents **EuiKeyPadMenuItems** in a tiled format, with a fixed width which will accommodate three items and then wrap.

**EuiKeyPadMenu** is just a wrapping element for creating the list elements: it yields a `Key` component (an `<li>`) that you wrap each item in.

If the menu provides navigation for your application, wrap the **EuiKeyPadMenu** with `<nav aria-label="Nav title"></nav>`.

</EuiText>

<EuiSpacer />

```gjs component
import { EuiIcon, EuiKeyPadMenu, EuiKeyPadMenuItem } from '@ember-eui/core/components';

<template>
<nav aria-label="Nav title">
  <EuiKeyPadMenu as |Key|>
    <Key>
      <EuiKeyPadMenuItem @label="Dashboard">
        <EuiIcon @type="dashboardApp" @size="l" />
      </EuiKeyPadMenuItem>
    </Key>

    <Key>
      <EuiKeyPadMenuItem @label="Canvas">
        <EuiIcon @type="canvasApp" @size="l" />
      </EuiKeyPadMenuItem>
    </Key>

    <Key>
      <EuiKeyPadMenuItem @isSelected={{true}} @label="Lens">
        <EuiIcon @type="lensApp" @size="l" />
      </EuiKeyPadMenuItem>
    </Key>

    <Key>
      <EuiKeyPadMenuItem @isDisabled={{true}} @label="Visualize">
        <EuiIcon @type="visualizeApp" @size="l" />
      </EuiKeyPadMenuItem>
    </Key>

    <Key>
      <EuiKeyPadMenuItem @label="Graph">
        <EuiIcon @type="graphApp" @size="l" />
      </EuiKeyPadMenuItem>
    </Key>

    <Key>
      <EuiKeyPadMenuItem @label="Advanced Settings">
        <EuiIcon @type="advancedSettingsApp" @size="l" />
      </EuiKeyPadMenuItem>
    </Key>
  </EuiKeyPadMenu>
</nav>
</template>
```
