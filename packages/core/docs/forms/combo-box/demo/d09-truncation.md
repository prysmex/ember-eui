---
order: 9
---

# Truncation

<EuiText>

By default, `EuiComboBox` truncates long option text at the end of the string. You can use `@truncationProps` and almost any argument that `EuiTextTruncate` accepts to configure this behavior. This can be configured at the `EuiComboBox` level, as well as by each individual option.

**Note:** setting `@rowHeight` to `"auto"` will cause truncation to be completely disabled.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { hash } from '@ember/helper';
import { on } from '@ember/modifier';
import { guidFor } from '@ember/object/internals';
import {
  EuiButtonGroup,
  EuiComboBox,
  EuiFieldNumber,
  EuiFlexGroup,
  EuiFlexItem,
  EuiSpacer,
  EuiTitle,
} from '@ember-eui/core/components';
import { or, eq } from 'ember-truth-helpers';

const options = [
  {
    label:
      'Lorem ipsum dolor sit amet, consectetur adipiscing elit, lorem ispum',
  },
  {
    label:
      'Phasellus enim turpis, molestie ut nisi ut, suscipit tristique libero',
  },
  {
    label: 'Ut sagittis interdum nisi, pellentesque laoreet arcu blandit a',
  },
  {
    label: 'Fusce sed viverra nisl',
  },
  {
    label: 'Donec maximus est justo, eget semper lorem lacinia nec',
  },
  {
    label: 'Vestibulum lobortis ipsum sit amet tellus scelerisque vestibulum',
  },
  {
    label: 'This combobox option has an individual `truncationProps` override',
    // Option `truncationProps` will override EuiComboBox `truncationProps`
    truncationProps: {
      truncation: 'start',
      truncationOffset: 5,
    },
  },
];

export default class ComboBoxTruncationDemo extends Component {
  options = options;
  offsetId = guidFor(this);

  truncationOptions = [
    { id: 'start', label: 'start ' },
    { id: 'end', label: 'end' },
    { id: 'startEnd', label: 'startEnd' },
    { id: 'middle', label: 'middle' },
  ];

  @tracked selectedOptions = [];
  @tracked truncation = 'end';
  @tracked truncationOffset = 0;

  @action
  onChange(selectedOptions) {
    this.selectedOptions = selectedOptions;
  }

  @action
  removeTag(option) {
    this.selectedOptions = this.selectedOptions.filter((o) => o !== option);
  }

  @action
  setTruncation(id) {
    this.truncation = id;
  }

  @action
  setTruncationOffset(event) {
    this.truncationOffset = Number(event.target.value);
  }

  <template>
    <EuiFlexGroup>
      <EuiFlexItem @grow={{false}}>
        <EuiTitle @size="xxs"><h3>Truncation type</h3></EuiTitle>
        <EuiSpacer @size="xs" />
        <EuiButtonGroup
          @legend="Truncation type"
          @idSelected={{this.truncation}}
          @onChange={{this.setTruncation}}
          @options={{this.truncationOptions}}
          @color="primary"
        />
      </EuiFlexItem>
      {{#if (or (eq this.truncation "start") (eq this.truncation "end"))}}
        <EuiFlexItem @grow={{false}}>
          <EuiTitle @size="xxs"><h3 id={{this.offsetId}}>Truncation offset</h3></EuiTitle>
          <EuiSpacer @size="xs" />
          <EuiFieldNumber
            aria-labelledby={{this.offsetId}}
            @value={{this.truncationOffset}}
            @compressed={{true}}
            {{on "input" this.setTruncationOffset}}
          />
        </EuiFlexItem>
      {{/if}}
    </EuiFlexGroup>
    <EuiSpacer />
    <EuiComboBox
      @placeholder="Select options"
      @options={{this.options}}
      @selectedOptions={{this.selectedOptions}}
      @searchField="label"
      @onChange={{this.onChange}}
      @removeTag={{this.removeTag}}
      @isClearable={{true}}
      @truncationProps={{hash
        truncation=this.truncation
        truncationOffset=this.truncationOffset
      }}
    />
  </template>
}
```
