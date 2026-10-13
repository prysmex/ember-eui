---
order: 6
---

# Tooltip on a fixed element

<EuiText>

Tooltips even work on `position: fixed;` elements. Add the `@repositionOnScroll` argument to ensure the tooltip realigns to the fixed anchor on scroll. It is also needed for a tooltip inside a scrollable container, while the anchor moves with that container. By default the tooltip is positioned when it opens and when the window is resized.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { EuiButton, EuiToolTip } from '@ember-eui/core/components';

export default class FixedToolTipDemo extends Component {
  @tracked isExampleShown = false;

  @action
  toggleExample() {
    this.isExampleShown = !this.isExampleShown;
  }

  <template>
    <EuiButton {{on 'click' this.toggleExample}}>Toggle fixed example</EuiButton>
    {{#if this.isExampleShown}}
      <div style='position: fixed; bottom: 50px; right: 50px; z-index: 10;'>
        <EuiToolTip
          @position='top'
          @content='This tooltip text scrolls with the fixed example button.'
          @repositionOnScroll={{true}}
        >
          <EuiButton @fill={{true}} {{on 'click' this.toggleExample}}>Toggle fixed example</EuiButton>
        </EuiToolTip>
      </div>
    {{/if}}
  </template>
}
```
