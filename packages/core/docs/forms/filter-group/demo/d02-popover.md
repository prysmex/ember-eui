---
order: 2
---

# Multi-select popover

<EuiText>

A filter button opening a popover of options. Clicking an option cycles
it through included (check), excluded (cross) and not applied. The badge
counts the applied options.

</EuiText>

```hbs template
<EuiFilterGroup>
  <EuiPopover
    @isOpen={{this.isOpen}}
    @closePopover={{this.close}}
    @panelPaddingSize="none"
    @anchorPosition="downCenter"
  >
    <:button>
      <EuiFilterButton
        @iconType="arrowDown"
        @isSelected={{this.isOpen}}
        @hasActiveFilters={{gt this.activeCount 0}}
        @numFilters={{this.options.length}}
        @numActiveFilters={{this.activeCount}}
        {{on "click" this.toggle}}
      >Composers</EuiFilterButton>
    </:button>
    <:content>
      <div class="euiFilterSelect__items" role="listbox" aria-label="Composers">
        {{#each this.options as |option|}}
          <EuiFilterSelectItem
            @checked={{option.checked}}
            {{on "click" (fn this.cycle option.name)}}
          >{{option.name}}</EuiFilterSelectItem>
        {{/each}}
      </div>
    </:content>
  </EuiPopover>
</EuiFilterGroup>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

const NEXT = { on: 'off', off: undefined, undefined: 'on' };

export default class FilterPopover extends Component {
  @tracked isOpen = false;
  @tracked options = [
    { name: 'Johann Sebastian Bach', checked: 'on' },
    { name: 'Wolfgang Amadeus Mozart' },
    { name: 'Antonín Dvořák', checked: 'off' },
    { name: 'Johannes Brahms' },
    { name: 'Franz Schubert' },
  ];

  get activeCount() {
    return this.options.filter((option) => option.checked).length;
  }

  @action
  toggle() {
    this.isOpen = !this.isOpen;
  }

  @action
  close() {
    this.isOpen = false;
  }

  @action
  cycle(name) {
    this.options = this.options.map((option) =>
      option.name === name
        ? { ...option, checked: NEXT[option.checked] }
        : option,
    );
  }
}
```
