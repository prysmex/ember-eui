---
order: 5
---

# Containers

This example demonstrates how the combo box works within containers. Because this component uses portals, it’s important that it works within other portal-using components.

```hbs template
<EuiFormRow
  @label='Combo box'
  @helpText='This combo box is inside of a form row'
>
  <EuiComboBox
    @onChange={{this.onChange}}
    @options={{this.groupedOptions}}
    @onCreateOption={{this.onCreateOption}}
    @selectedOptions={{this.selected}}
    @searchEnabled={{true}}
    @customOptionText='Do you want to add&nbsp;{searchText}&nbsp;to your list?'
    @searchField='label'
    as |option item|
  >
    {{option.label}}
  </EuiComboBox>

</EuiFormRow>

<EuiFlexGroup @responsive={{false}} @direction='columm'>
  <EuiFlexItem @grow={{false}}>
    <EuiButton {{on 'click' (set this 'showModal' (not this.showModal))}}>
      Show Modal
    </EuiButton>
  </EuiFlexItem>

  <EuiFlexItem @grow={{false}}>
    <EuiPopover
      @ownFocus={{true}}
      @isOpen={{this.showPopover}}
      @anchorPosition='downLeft'
      @closePopover={{set this 'showPopover' false}}
    >
      <:button>
        <EuiButton
          @iconType='arrowDown'
          @iconSide='right'
          {{on 'click' (set this 'showPopover' true)}}
        >
          Open popover
        </EuiButton>
      </:button>
      <:content>
        <div style='width:300px;'>
          <EuiComboBox
            @onChange={{this.onChange}}
            @options={{this.groupedOptions}}
            @onCreateOption={{this.onCreateOption}}
            @selectedOptions={{this.selected}}
            @searchEnabled={{true}}
            @customOptionText='Do you want to add&nbsp;{searchText}&nbsp;to your list?'
            @searchField='label'
            as |option item|
          >
            {{option.label}}
          </EuiComboBox>
        </div>
      </:content>
    </EuiPopover>
  </EuiFlexItem>
</EuiFlexGroup>

{{#if this.showModal}}
  <EuiModal @onClose={{set this 'showModal' false}}>
    <EuiModalHeader>
      <EuiModalHeaderTitle>
        <h1>Combo box in a modal</h1>
      </EuiModalHeaderTitle>
    </EuiModalHeader>
    <EuiModalBody>
      <EuiComboBox
        @onChange={{this.onChange}}
        @options={{this.groupedOptions}}
        @onCreateOption={{this.onCreateOption}}
        @selectedOptions={{this.selected}}
        @searchEnabled={{true}}
        @customOptionText='Do you want to add&nbsp;{searchText}&nbsp;to your list?'
        @searchField='label'
        as |option item|
      >
        {{option.label}}
      </EuiComboBox>
    </EuiModalBody>
  </EuiModal>
{{/if}}
```

```javascript component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class extends Component {
  @tracked selected = [];
  @tracked options = [];
  @tracked groupedOptions = [];
  @tracked showModal = false;
  @tracked showPopover = false;

  constructor() {
    super(...arguments);
    this.options = [
      { value: 'No group option', label: 'No group option', color: 'red' },
      { groupName: 'Group 1', options: this.generateArray('group1', 3) },
      { groupName: 'Group 2', options: this.generateArray('group2', 5) }
    ];
    this.groupedOptions = this.options.slice();
  }
  generateArray(prefix, n) {
    let arr = [];
    for (let i = 0; i < n - 1; i++) {
      arr[i] = {
        value: i,
        label: `${prefix} Number ${i}`,
        color: '#' + (((1 << 24) * Math.random()) | 0).toString(16)
      };
    }
    return arr;
  }

  @action
  onChange(selected) {
    this.groupedOptions = this.options.filter((opt) => !selected.includes(opt));
    this.selected = selected;
  }

  @action
  onCreateOption(newOption) {
    const newOptionStructure = {
      value: `${newOption}`,
      label: `${newOption}`
    };
    if (
      this.options.filter((opt) => opt.value == newOptionStructure.value)
        .length == 0
    ) {
      this.options.addObject(newOptionStructure);
      this.selected.addObject(newOptionStructure);
    }
  }
}
```
