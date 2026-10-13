---
order: 8
---

# Truncation

<EuiText>

`EuiSelectable` defaults to `@listProps.textWrap="truncate"`, which truncates long option text at the end of the string.

You can use `@listProps.truncationProps` and almost any argument that `EuiTextTruncate` accepts to configure this behavior. This can be configured at the `EuiSelectable` level, as well as by each individual option.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { EuiButtonGroup, EuiFieldNumber, EuiFlexGroup, EuiFlexItem, EuiIcon, EuiPanel, EuiSelectable, EuiSpacer, EuiText, EuiTitle } from '@ember-eui/core/components';

export default class SelectableTruncationDemo extends Component {
  @tracked options = [
    { label: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, lorem ispum', checked: 'on' },
    { label: 'Phasellus enim turpis, molestie ut nisi ut, suscipit tristique libero' },
    { label: 'Ut sagittis interdum nisi, pellentesque laoreet arcu blandit a' },
    { label: 'Fusce sed viverra nisl' },
    { label: 'Donec maximus est justo, eget semper lorem lacinia nec' },
    { label: 'Vestibulum lobortis ipsum sit amet tellus scelerisque vestibulum' },
    {
      label: 'This option has `textWrap` and `truncationProps` settings that will override the parent',
      hasWarning: true,
      textWrap: 'truncate',
      truncationProps: { truncation: 'start', truncationOffset: 5 },
    },
  ];

  @tracked textWrap = 'truncate';
  @tracked truncation = 'end';
  @tracked truncationOffset = 0;

  textWrapOptions = [
    { id: 'truncate', label: 'truncate' },
    { id: 'wrap', label: 'wrap' },
  ];

  truncationOptions = [
    { id: 'start', label: 'start' },
    { id: 'end', label: 'end' },
    { id: 'startEnd', label: 'startEnd' },
    { id: 'middle', label: 'middle' },
  ];

  get isTruncate() {
    return this.textWrap === 'truncate';
  }

  get showOffset() {
    return this.isTruncate && (this.truncation === 'start' || this.truncation === 'end');
  }

  get listProps() {
    return {
      isVirtualized: this.textWrap !== 'wrap',
      textWrap: this.textWrap,
      truncationProps: {
        truncation: this.truncation,
        truncationOffset: this.truncationOffset,
      },
    };
  }

  @action
  setOptions(options) {
    this.options = options;
  }

  @action
  setTextWrap(id) {
    this.textWrap = id;
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
        <EuiTitle @size="xxs"><h3>Text wrap</h3></EuiTitle>
        <EuiSpacer @size="xs" />
        <EuiButtonGroup
          @legend="Text wrap"
          @idSelected={{this.textWrap}}
          @onChange={{this.setTextWrap}}
          @options={{this.textWrapOptions}}
          @color="primary"
        />
      </EuiFlexItem>
      {{#unless this.isTruncate}}
        <EuiFlexItem @grow={{false}} style="align-self: center">
          <EuiText @color="danger" @size="s">
            <EuiIcon @type="warning" /> Wrapping text requires disabling
            virtualization. We do not recommend this for large (50+) amounts
            of options.
          </EuiText>
        </EuiFlexItem>
      {{/unless}}
      {{#if this.isTruncate}}
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
      {{/if}}
      {{#if this.showOffset}}
        <EuiFlexItem @grow={{false}}>
          <EuiTitle @size="xxs"><h3 id="selectableTruncationOffset">Truncation offset</h3></EuiTitle>
          <EuiSpacer @size="xs" />
          <EuiFieldNumber
            aria-labelledby="selectableTruncationOffset"
            @value={{this.truncationOffset}}
            @compressed={{true}}
            {{on "input" this.setTruncationOffset}}
          />
        </EuiFlexItem>
      {{/if}}
    </EuiFlexGroup>
    <EuiSpacer />
    <EuiPanel @paddingSize="s" style="inline-size: 400px; resize: horizontal; overflow: auto">
      <EuiSelectable
        @searchable={{true}}
        @options={{this.options}}
        @onChange={{this.setOptions}}
        @listProps={{this.listProps}}
      >
        <:optionPrepend as |option|>
          {{#if option.hasWarning}}
            <EuiIcon @type="warning" @color="warning" aria-label="Note!" />
          {{/if}}
        </:optionPrepend>
      </EuiSelectable>
    </EuiPanel>
  </template>
}
```
