---
order: 4
---

# Fixed width and delayed calculation

<EuiText>

Every `EuiTextTruncate` observes its own width. When many items share one
container, measure the container once and pass `@width`; no observer is
created then. `@onResize` reports each measured width when observing.
`@calculationDelayMs` waits before truncating, for fonts or layout that
settle late; the full text shows meanwhile.

</EuiText>

```hbs template
<div {{resize-observer onResize=this.onResize}} style="max-width: 320px">
  <EuiText @size="xs" @color="subdued"><p>Container width: {{this.width}}px</p></EuiText>
  {{#each this.items as |item|}}
    <EuiTextTruncate @text={{item}} @width={{this.width}} @truncation="middle" />
  {{/each}}
  <EuiSpacer @size="s" />
  <EuiTextTruncate @text={{this.delayed}} @calculationDelayMs={{500}} />
</div>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class TruncationPerformance extends Component {
  @tracked width = 0;

  items = Array.from(
    { length: 5 },
    (_, i) => `cluster-${i + 1}/indices/logs-application-production-2026.10.${10 + i}`
  );
  delayed = 'This one waits half a second before measuring, then truncates at the end';

  @action
  onResize({ width }) {
    this.width = Math.floor(width);
  }
}
```
