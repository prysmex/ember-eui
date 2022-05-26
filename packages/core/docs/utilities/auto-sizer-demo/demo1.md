---
order: 1
---

<EuiText>
	<p>
	<strong>EuiAutoSizer</strong> helps components that use virtualized rendering and/or require explicit dimensions to fill all available space in the parent container. See the <EuiLink @href="https://github.com/bvaughn/react-virtualized/blob/master/docs/AutoSizer.md">react-virtualized</EuiLink> documentation as <strong>EuiAutoSizer</strong> is a port from component for <strong>AutoSizer</strong>.
  </p>
</EuiText>

```hbs template
<div style='height:200px; width: 100%;'>
  <EuiAutoSizer as |dimensions|>
    <EuiPanel
      style='position: absolute; display: flex; align-items:center; justify-content:center; height: {{dimensions.height}}; width: {{dimensions.width}}'
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
