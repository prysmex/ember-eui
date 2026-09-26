---
order: 1
---

# Auto sizer

```hbs template
<div style='height:200px; width: 100%;'>
  <EuiAutoSizer as |dimensions|>
    <EuiPanel
      style='position: absolute; display: flex; align-items:center; justify-content:center; height: {{dimensions.height}}px; width: {{dimensions.width}}px'
    >
      <EuiCode>height:
        {{dimensions.height}}, width:
        {{dimensions.width}}</EuiCode>
    </EuiPanel>
  </EuiAutoSizer>
</div>
```

```javascript component
import GlimmerComponent from '@glimmer/component';
import { tracked } from '@glimmer/tracking';

export default class OutsideClickDetectorComponentDemo1 extends GlimmerComponent {
  @tracked copyText = 'I am the text that will be copied';
}
```
