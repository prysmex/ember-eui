---
order: 1
---

# Paste rules

<EuiText>

A pasted text that matches no option is handled per field. Color has
fixed options: an unknown value is rejected, and the cell shows the
text marked invalid. Tag has `createOnPaste: true`: an unknown value
becomes a new option, listed in the change set's `newOptions`.
`localRecords` adds it to its fields (with your own store, use
`applyNewOptions`). Options are only created on paste; typing an
unknown tag in the editor finds nothing.

Copy the block below (or use the button), select the first Color cell
and paste. The last row of the block goes past the end, so it is an
insert.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { EuiBadge, EuiButton, EuiCodeBlock, EuiFlexGroup, EuiFlexItem, EuiSpacer, EuiText } from '@ember-eui/core/components';
import { EuiSheet, localRecords } from '@ember-eui/sheet';

const FIELDS = [
  { id: 'name', label: 'Product' },
  {
    id: 'color',
    label: 'Color',
    type: 'singleSelect',
    options: [
      { value: 'red', label: 'Red', color: 'danger' },
      { value: 'green', label: 'Green', color: 'success' },
      { value: 'blue', label: 'Blue', color: 'primary' },
    ],
  },
  {
    id: 'tag',
    label: 'Tag',
    type: 'singleSelect',
    createOnPaste: true,
    options: [{ value: 'new', label: 'New' }],
  },
];

const RECORDS = [
  { id: 'c1', name: 'Helmet', color: 'red', tag: 'new' },
  { id: 'c2', name: 'Vest', color: null, tag: null },
  { id: 'c3', name: 'Boots', color: 'blue', tag: null },
];

const BLOCK = 'green\tSale\nPurple\tnew\nRed\tClearance\nBlue\tSale';

export default class SheetPasteRules extends Component {
  getId = (record) => record.id;
  store = localRecords(RECORDS, { getRecordId: this.getId, fields: FIELDS });
  block = BLOCK;

  @tracked last = null;
  @tracked copied = false;

  onChange = (changeSet) => {
    this.store.apply(changeSet);
    this.last = changeSet;
  };

  get tagOptions() {
    return this.store.fields.find((field) => field.id === 'tag').options;
  }

  get summary() {
    if (!this.last) return '// paste the block on the first Color cell';
    const { source, patches, inserts, rejected, newOptions } = this.last;
    return JSON.stringify({ source, patches: patches.length, inserts, rejected, newOptions }, null, 2);
  }

  copy = async () => {
    // the clipboard API needs a secure context (https or localhost)
    if (!navigator.clipboard) return;
    await navigator.clipboard.writeText(BLOCK);
    this.copied = true;
  };

  <template>
    <EuiFlexGroup @gutterSize='l' @wrap={{true}}>
      <EuiFlexItem @grow={{2}}>
        <EuiSheet
          @fields={{this.store.fields}}
          @records={{this.store.records}}
          @getRecordId={{this.getId}}
          @onChange={{this.onChange}}
          @height={{220}}
          @ariaLabel='Products'
        />
        <EuiSpacer @size='s' />
        <EuiText @size='s'>
          Tag options:
          {{#each this.tagOptions as |option|}}
            <EuiBadge @color='hollow'>{{option.label}}</EuiBadge>
          {{/each}}
        </EuiText>
      </EuiFlexItem>
      <EuiFlexItem @grow={{1}}>
        <EuiCodeBlock @fontSize='s' @paddingSize='s' @isCopyable={{true}}>{{this.block}}</EuiCodeBlock>
        <EuiSpacer @size='s' />
        <EuiButton @size='s' {{on 'click' this.copy}}>{{if this.copied 'Copied' 'Copy the block'}}</EuiButton>
        <EuiSpacer @size='s' />
        <EuiCodeBlock @language='json' @fontSize='s' @paddingSize='s' @overflowHeight={{260}}>{{this.summary}}</EuiCodeBlock>
      </EuiFlexItem>
    </EuiFlexGroup>
  </template>
}
```
