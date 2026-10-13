---
order: 2
---

# Positions

<EuiText>
  <p>
    Bottom bars default to a fixed position, in a portal at the bottom of the browser window. Alternatively, you can change the <EuiCode>@position</EuiCode> to <EuiCode>sticky</EuiCode> where it will render in place but stick to the window only as the window edge nears. The <EuiCode>static</EuiCode> position reverts back to default DOM behavior.
  </p>
  <p>
    You can also apply a different set of positioning locations just by adjusting them in with the <EuiCode>top | right | bottom | left</EuiCode> arguments.
  </p>
</EuiText>

```gjs component
import { EuiBottomBar, EuiText } from '@ember-eui/core/components';

<template>
  <div style='overflow: auto; block-size: 200px;'>
    <EuiText>
      <p>
        When scrolling within this example, the <strong>EuiBottomBar</strong> will stick to the bottom of scrollable container (with a 10px offset), but will not scroll with the page itself.
      </p>
    </EuiText>
    <div style='block-size: 400px;'></div>
    <EuiBottomBar @position='sticky' @bottom={{10}}>
      <EuiText @textAlign='center'>
        <p>Scroll to see!</p>
      </EuiText>
    </EuiBottomBar>
  </div>
</template>
```
