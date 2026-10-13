---
order: 6
---

# Performance

<EuiText>

`EuiTextTruncate` uses a canvas element under the hood to manipulate text and calculate whether the text width fits within the available width. Additionally, by default, the component will include its own resize observer in order to react to width changes.

These functionalities can cause performance issues if the component is rendered over hundreds of times per page, and we would strongly recommend using caution when doing so. Several escape hatches are available for performance improvements:

1. Pass a `@width` argument to skip initializing a resize observer for each component instance. For text within a container of the same width, we would strongly recommend applying a single resize observer to the parent container and passing that width to all child `EuiTextTruncate`s.
2. Use virtualization to reduce the number of rendered elements visible at any given time. For over hundreds of instances, this will generally be the most effective solution for performance or rerender issues.
3. If necessary, consider reusing the same canvas context, as opposed to repeatedly creating new ones.

`@calculationDelayMs` waits before truncating, for fonts or layout that settle late; the full text shows meanwhile.

</EuiText>

```gjs component
import { resizeObserver } from '@ember-eui/core/modifiers';
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiFieldNumber, EuiFlexGroup, EuiFormRow, EuiPanel, EuiSpacer, EuiSwitch, EuiText, EuiTextTruncate } from '@ember-eui/core/components';
import { on } from '@ember/modifier';

const words = 'lorem ipsum dolor sit amet consectetur adipiscing elit sed do eiusmod tempor incididunt ut labore et dolore magna aliqua'.split(' ');

export default class extends Component {
  @tracked lineCount = 100;
  @tracked shareWidth = true;
  @tracked width = 200;

  get lines() {
    return Array.from({ length: this.lineCount }, (_, i) =>
      Array.from({ length: 30 }, (_, j) => words[(i * 7 + j * 3) % words.length]).join(' ')
    );
  }

  get widthArg() {
    return this.shareWidth ? this.width : undefined;
  }

  @action
  setLineCount(event) {
    this.lineCount = Number(event.target.value);
  }

  @action
  toggleShareWidth() {
    this.shareWidth = !this.shareWidth;
  }

  @action
  onResize({ width }) {
    this.width = Math.floor(width);
  }

  <template>
    <EuiText>
      <EuiFlexGroup @alignItems='center' @gutterSize='xl'>
        <EuiFormRow @label='Lines' @display='columnCompressed'>
          <EuiFieldNumber
            @compressed={{true}}
            @value={{this.lineCount}}
            style='width: 100px'
            {{on 'input' this.setLineCount}}
          />
        </EuiFormRow>
        <EuiSwitch
          @label='Share one observer (pass @width)'
          @checked={{this.shareWidth}}
          @onChange={{this.toggleShareWidth}}
        />
      </EuiFlexGroup>
      <EuiSpacer @size='m' />
      <EuiPanel style='overflow: auto; resize: inline; max-inline-size: 100%; inline-size: 600px; block-size: 300px;'>
        <div {{resizeObserver onResize=this.onResize}}>
          {{#each this.lines as |line|}}
            <EuiTextTruncate
              @text={{line}}
              @truncation='middle'
              @width={{this.widthArg}}
            />
          {{/each}}
        </div>
      </EuiPanel>
      <EuiSpacer />
      <p>
        Drag the panel resize handle to test performance. Use the controls above
        to compare the performance of different approaches.
      </p>
    </EuiText>
  </template>
}
```

