---
order: 1
---

# Auto sizer

```gjs component
import { htmlSafe } from '@ember/template';
import GlimmerComponent from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { EuiAutoSizer, EuiCode, EuiPanel } from '@ember-eui/core/components';

const panelStyle = (d) =>
  htmlSafe(
    `position: absolute; display: flex; align-items:center; justify-content:center; height: ${d.height}px; width: ${d.width}px`
  );

export default class OutsideClickDetectorComponentDemo1 extends GlimmerComponent {
  @tracked copyText = 'I am the text that will be copied';

  <template>
    <div style='height:200px; width: 100%;'>
      <EuiAutoSizer as |dimensions|>
        <EuiPanel
          style={{panelStyle dimensions}}
        >
          <EuiCode>height:
            {{dimensions.height}}, width:
            {{dimensions.width}}</EuiCode>
        </EuiPanel>
      </EuiAutoSizer>
    </div>
  </template>
}
```

