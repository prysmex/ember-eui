---
order: 9
---

# When content changes dynamically

<EuiText>
  If an accordion’s content changes height while the accordion is open, it will
  resize dynamically.
</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { eq, gt } from 'ember-truth-helpers';
import { EuiAccordion, EuiButton, EuiPanel, EuiScreenReaderOnly, EuiSpacer, EuiText } from '@ember-eui/core/components';

const add = (a, b) => a + b;
const range = (start, end) => Array.from({ length: Math.max(0, end - start) }, (_, i) => start + i);
const sub = (a, b) => a - b;

export default class AccordionDynamicComponent extends Component {
  @tracked counter = 1;

  @action
  increase() {
    this.counter++;
  }

  @action
  decrease() {
    this.counter = Math.max(1, this.counter - 1);
  }

  <template>
  <EuiAccordion
    @id="dynamicAccordion"
    @paddingSize="s"
    @initialIsOpen={{true}}
  >
    <:buttonContent>
      Click me to toggle close / open
    </:buttonContent>
    <:content>
      <EuiPanel @color="subdued">
        <EuiText @size="s">
          <EuiScreenReaderOnly>
            <p id="growingAccordionDescription">
              Currently height is set to {{this.counter}} items
            </p>
          </EuiScreenReaderOnly>
          <EuiSpacer @size="s" />
          <p>
            <EuiButton
              @size="s"
              @iconType="plusCircle"
              aria-controls="dynamicAccordionList"
              aria-describedby="growingAccordionDescription"
              {{on "click" this.increase}}
            >
              Increase height to {{add this.counter 1}} items
            </EuiButton>
            {{" "}}
            <EuiButton
              @size="s"
              @iconType="minusCircle"
              aria-controls="dynamicAccordionList"
              aria-describedby="growingAccordionDescription"
              @isDisabled={{eq this.counter 1}}
              {{on "click" this.decrease}}
            >
              Decrease height to {{sub this.counter 1}}
              {{if (gt this.counter 2) "items" "item"}}
            </EuiButton>
          </p>
          <ul id="dynamicAccordionList">
            {{#each (range 1 (add this.counter 1)) as |row|}}
              <li>Row {{row}}</li>
            {{/each}}
          </ul>
        </EuiText>
      </EuiPanel>
    </:content>
  </EuiAccordion>
  </template>
}
```
