---
order: 12
---

# Popover using an HTML Element as the anchor

```hbs template
{{#each this.buttons key='id' as |ele|}}
  {{ele.button}}
{{/each}}

{{#if this.isOpen}}
  <EuiWrappingPopover
    @button={{this.button}}
    @isOpen={{this.isOpen}}
    @closePopover={{this.closePopover}}
  >
    <div>Normal JSX content populates the popover.</div>
  </EuiWrappingPopover>
{{/if}}
```

```javascript component
import Component from '@glimmer/component';
import { action } from '@ember/object';
import { tracked } from '@glimmer/tracking';
import { next } from '@ember/runloop';

export default class PopoverDemo1 extends Component {
  @tracked isOpen = false;
  @tracked button = null;
  @tracked counter = 1;

  @tracked buttons = [];

  closePopover = () => {
    this.isOpen = false;
    this.createButton();
  };

  createButton = () => {
    const button = document.createElement('div');

    button.innerHTML = `This is a dynamically inserted html node with <b>ID = ${this.counter}</b>, if you click, you will get a popover on it.`;

    button.addEventListener('click', () => {
      this.isOpen = true;
      this.button = button;
    });

    const ele = {
      button,
      id: `${this.counter}`
    };

    this.buttons = [...this.buttons, ele];
    this.counter++;
  };

  constructor() {
    super(...arguments);

    next(() => {
      this.createButton();
    });
  }
}
```
