---
order: 12
---

# View intents: sort, hide, move, widths, row height, search

<EuiText>

The sheet never sorts, filters or searches: it draws the owner's state
and tells the owner what the user asked for. Here a small owner (the demo
component) does the work with its own array:

- **Sort**: the column menu's "Sort" items call `@onSortChange`. The owner
  sorts its records (after a fake 300 ms query, with `@isLoading`) and
  passes `@sort` back, which draws the arrows. A second sort is added to
  the first.
- **Hide, move, resize**: the menu's "Hide column" and "Move left/right",
  and dragging a column's edge, call `@onHiddenFieldsChange`,
  `@onFieldOrderChange` and `@onFieldWidthChange`; the owner updates
  `@fields`, `@hiddenFields` and `@fieldWidths`. The first field cannot be
  hidden or moved, and stays in view when you scroll right (it is frozen,
  `@frozenFields={{1}}`).
- **The toolbar** is the app's, in the sheet's `<:toolbar>` block: a search
  box (the owner filters its records and passes the term as `@highlight`),
  the row height (the block's `setRowHeight`, which calls
  `@onRowHeightChange`) and a field picker (`hideField`, `showField`).
- **Filter by this field** in the menu calls `@onFilterByField`; this demo
  only logs it, where your filter UI would open.
- "Name" and "Notes" have a `description`: the header's info icon, and the
  text under the label in the expanded record (Space on a cell).

The log on the right shows each intent as the sheet emitted it.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { fn } from '@ember/helper';
import {
  EuiButtonGroup,
  EuiCodeBlock,
  EuiFieldSearch,
  EuiFlexGroup,
  EuiFlexItem,
  EuiSwitch,
  EuiText,
  EuiTitle,
} from '@ember-eui/core/components';
import { EuiSheet, applyChangeSet, builtInFieldTypes } from '@ember-eui/sheet';

const ALL_FIELDS = [
  { id: 'name', label: 'Name', required: true, description: 'The worker’s full name' },
  { id: 'city', label: 'City' },
  { id: 'hours', label: 'Hours', type: 'number', min: 0 },
  { id: 'start', label: 'Start', type: 'date' },
  { id: 'active', label: 'Active', type: 'checkbox' },
  { id: 'notes', label: 'Notes', description: 'Anything else about this worker' },
];

const RECORDS = Array.from({ length: 24 }, (_, i) => ({
  id: `w${i + 1}`,
  name: ['Ana', 'Luis', 'Marta', 'Jorge', 'Sofía', 'Pablo'][i % 6] + ` ${i + 1}`,
  city: ['Monterrey', 'Madrid', 'Lima', 'Bogotá'][i % 4],
  hours: (i * 7) % 40,
  start: `2026-${String(1 + (i % 12)).padStart(2, '0')}-${String(1 + ((i * 3) % 28)).padStart(2, '0')}`,
  active: i % 3 !== 0,
  notes: i % 5 === 0 ? 'Needs training' : '',
}));

const HEIGHTS = [
  { id: 'short', label: 'Short' },
  { id: 'medium', label: 'Medium' },
  { id: 'tall', label: 'Tall' },
];

const byId = (id) => ALL_FIELDS.find((field) => field.id === id);
const isShown = (fields, id) => fields.some((field) => field.id === id);
const sortText = (sort) =>
  sort.length
    ? `sorted by ${sort.map(({ field, direction }) => `${byId(field).label} ${direction}`).join(', then ')}`
    : 'not sorted';

export default class SheetViewIntents extends Component {
  getId = (record) => record.id;
  heights = HEIGHTS;
  allFields = ALL_FIELDS;

  // the owner's state: its records and the view of them
  @tracked records = RECORDS;
  @tracked visibleIds = ['name', 'city', 'hours', 'start', 'active'];
  @tracked widths = { name: 180 };
  @tracked rowHeight = 'short';
  @tracked sort = [];
  @tracked query = '';
  @tracked isLoading = false;
  @tracked intents = [];

  get fields() {
    return this.visibleIds.map(byId);
  }

  get hiddenFields() {
    return ALL_FIELDS.filter((field) => !this.visibleIds.includes(field.id));
  }

  // what the sheet shows: the owner filters and sorts, the sheet never does
  get shown() {
    const query = this.query.trim().toLowerCase();
    let records = query
      ? this.records.filter((record) =>
          [record.name, record.city, record.notes].some((value) =>
            String(value ?? '').toLowerCase().includes(query),
          ),
        )
      : this.records;
    if (this.sort.length) {
      records = [...records].sort((a, b) => {
        for (const { field, direction } of this.sort) {
          const type = builtInFieldTypes[byId(field).type ?? 'text'];
          const order = type.compare(a[field], b[field], byId(field));
          if (order) return direction === 'asc' ? order : -order;
        }
        return 0;
      });
    }
    return records;
  }

  log(name, value) {
    this.intents = [`${name}(${JSON.stringify(value)})`, ...this.intents].slice(0, 12);
  }

  onChange = (changeSet) => {
    this.records = applyChangeSet(this.records, changeSet, { getRecordId: this.getId });
    this.log('onChange', changeSet.source);
  };

  onSortChange = (sort) => {
    this.log('onSortChange', sort);
    this.isLoading = true;
    // a query to a server would take a while
    setTimeout(() => {
      this.sort = sort;
      this.isLoading = false;
    }, 300);
  };

  onHiddenFieldsChange = (ids) => {
    this.log('onHiddenFieldsChange', ids);
    const shown = this.visibleIds.filter((id) => !ids.includes(id));
    const added = ALL_FIELDS.map((field) => field.id).filter(
      (id) => !ids.includes(id) && !shown.includes(id),
    );
    this.visibleIds = [...shown, ...added];
  };

  onFieldOrderChange = (ids) => {
    this.log('onFieldOrderChange', ids);
    this.visibleIds = ids;
  };

  onFieldWidthChange = (id, width) => {
    this.log('onFieldWidthChange', [id, width]);
    this.widths = { ...this.widths, [id]: width };
  };

  onRowHeightChange = (rowHeight) => {
    this.log('onRowHeightChange', rowHeight);
    this.rowHeight = rowHeight;
  };

  onFilterByField = (id) => {
    this.log('onFilterByField', id);
  };

  search = (query) => {
    this.query = query;
  };

  toggleField = (sheet, id, event) => {
    if (event.target.checked) sheet.showField(id);
    else sheet.hideField(id);
  };

  get logText() {
    return this.intents.length ? this.intents.join('\n') : '// sort, hide, move or resize a column';
  }

  <template>
    <EuiFlexGroup @gutterSize='l' @wrap={{true}}>
      <EuiFlexItem @grow={{2}} style='min-width: 0'>
        <EuiSheet
          @fields={{this.fields}}
          @hiddenFields={{this.hiddenFields}}
          @records={{this.shown}}
          @getRecordId={{this.getId}}
          @onChange={{this.onChange}}
          @sort={{this.sort}}
          @onSortChange={{this.onSortChange}}
          @onHiddenFieldsChange={{this.onHiddenFieldsChange}}
          @onFieldOrderChange={{this.onFieldOrderChange}}
          @fieldWidths={{this.widths}}
          @onFieldWidthChange={{this.onFieldWidthChange}}
          @rowHeight={{this.rowHeight}}
          @onRowHeightChange={{this.onRowHeightChange}}
          @onFilterByField={{this.onFilterByField}}
          @highlight={{this.query}}
          @isLoading={{this.isLoading}}
          @frozenFields={{1}}
          @height={{380}}
          @ariaLabel='Workers'
        >
          <:toolbar as |sheet|>
            <EuiFlexGroup @gutterSize='s' @alignItems='center' @wrap={{true}} @responsive={{false}}>
              <EuiFlexItem @grow={{false}}>
                <EuiFieldSearch
                  @value={{this.query}}
                  @onSearch={{this.search}}
                  @incremental={{true}}
                  @isClearable={{true}}
                  @compressed={{true}}
                  placeholder='Search name, city, notes'
                  aria-label='Search workers'
                />
              </EuiFlexItem>
              <EuiFlexItem @grow={{false}}>
                <EuiButtonGroup
                  @legend='Row height'
                  @options={{this.heights}}
                  @idSelected={{sheet.rowHeight}}
                  @onChange={{sheet.setRowHeight}}
                  @buttonSize='compressed'
                />
              </EuiFlexItem>
              {{#each this.allFields as |field index|}}
                <EuiFlexItem @grow={{false}}>
                  <EuiSwitch
                    @compressed={{true}}
                    @label={{field.label}}
                    @checked={{isShown sheet.fields field.id}}
                    @disabled={{if index false true}}
                    @onChange={{fn this.toggleField sheet field.id}}
                  />
                </EuiFlexItem>
              {{/each}}
            </EuiFlexGroup>
          </:toolbar>
          <:footer as |sheet|>
            <EuiText @size='xs' @color='subdued'>
              <p>
                {{this.shown.length}} of {{this.records.length}} records;
                {{sheet.fields.length}} fields shown, {{sheet.hiddenFields.length}} hidden;
                {{sortText sheet.sort}}.
              </p>
            </EuiText>
          </:footer>
        </EuiSheet>
      </EuiFlexItem>
      <EuiFlexItem @grow={{1}}>
        <EuiTitle @size='xxs'><h4>Intents</h4></EuiTitle>
        <EuiCodeBlock @fontSize='s' @paddingSize='s' @overflowHeight={{420}}>{{this.logText}}</EuiCodeBlock>
      </EuiFlexItem>
    </EuiFlexGroup>
  </template>
}
```
