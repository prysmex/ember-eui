---
order: 4
---

# Custom cells and editors

<EuiText>

Zone is an app field type registered with `@fieldTypes`: its value is
`{ id, label }`, and its editor searches a fake API that answers after
400 ms. Its zones depend on the row's Site; type `fail` to see the
error state. Position is a `singleSelect` whose `options` is a function
of the record, so its choices follow Area; change Area and an old
Position is kept and marked "is not an option" rather than cleared.
Company is read-only unless Contractor is checked, and required when it
is.

A zone cannot be pasted yet: its type returns `{ unresolved }` for
text, which v0.1 rejects ("could not be resolved"), so copying a Zone
cell and pasting it gives an error.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { EuiPanel, EuiSelectable } from '@ember-eui/core/components';
import { EuiSheet, localRecords } from '@ember-eui/sheet';

const ZONES = {
  north: ['Warehouse 1', 'Warehouse 2', 'Loading dock', 'Offices'],
  south: ['Boiler room', 'Paint line', 'Assembly', 'Cafeteria', 'Parking'],
};

/** A fake API: the site's zones matching `query`, after 400 ms. */
function searchZones(site, query) {
  return new Promise((resolve, reject) => {
    setTimeout(() => {
      if (query.trim().toLowerCase() === 'fail') {
        reject(new Error('Server error'));
        return;
      }
      const zones = (ZONES[site] ?? [])
        .filter((name) => name.toLowerCase().includes(query.trim().toLowerCase()))
        .map((name) => ({ id: `${site}-${name}`, label: name }));
      resolve(zones);
    }, 400);
  });
}

class ZoneEditor extends Component {
  @tracked options = [];
  @tracked isLoading = false;
  @tracked error = null;
  request = 0;
  active = null;

  get label() {
    return this.args.field.label ?? this.args.field.id;
  }

  searchProps = {
    compressed: true,
    defaultValue: this.args.initialKey ?? '',
    inputRef: (input) => input.focus(),
    // also called once after the first render
    onChange: (query) => void this.search(query),
  };

  async search(query) {
    const request = ++this.request;
    this.isLoading = true;
    this.error = null;
    try {
      const zones = await searchZones(this.args.record?.site, query);
      if (request !== this.request || this.isDestroying) return; // a newer search is running
      this.options = zones.map((zone) => ({
        label: zone.label,
        key: zone.id,
        checked: zone.id === this.args.value?.id ? 'on' : undefined,
        data: { value: zone },
      }));
    } catch {
      if (request === this.request && !this.isDestroying) this.error = 'Could not load zones';
    } finally {
      if (request === this.request && !this.isDestroying) this.isLoading = false;
    }
  }

  pick = (_options, event, changed) => {
    this.args.onCommit({ value: changed.data.value }, { move: event instanceof KeyboardEvent ? [1, 0] : [0, 0] });
  };

  setActive = (option) => {
    this.active = option;
  };

  // with a typed search no option is current yet: Enter picks the first one
  onKeyDown = (event) => {
    if (event.key === 'Enter' && !this.active && this.options.length && !this.isLoading) {
      event.preventDefault();
      event.stopPropagation();
      this.args.onCommit({ value: this.options[0].data.value }, { move: [1, 0] });
    }
  };

  // a press on an option keeps focus in the search field, so the editor stays open
  keepFocus = (event) => {
    if (!(event.target instanceof HTMLInputElement)) event.preventDefault();
  };

  <template>
    <div {{on 'keydown' this.onKeyDown capture=true}} {{on 'mousedown' this.keepFocus}}>
      <EuiPanel @paddingSize='s' @hasShadow={{true}}>
        <EuiSelectable
          aria-label={{this.label}}
          @options={{this.options}}
          @singleSelection='always'
          @searchable={{true}}
          @isPreFiltered={{true}}
          @isLoading={{this.isLoading}}
          @errorMessage={{this.error}}
          @searchProps={{this.searchProps}}
          @onChange={{this.pick}}
          @onActiveOptionChange={{this.setActive}}
        />
      </EuiPanel>
    </div>
  </template>
}

const zoneType = {
  parse: (text) => (text.trim() === '' ? { value: null } : { unresolved: text.trim() }),
  format: (value) => value?.label ?? '',
  isEmpty: (value) => value == null,
  editor: ZoneEditor,
  editorLayout: 'panel',
  handlesKey: (event) => ['Enter', 'ArrowUp', 'ArrowDown'].includes(event.key),
};

const POSITIONS = {
  production: [
    { value: 'operator', label: 'Operator' },
    { value: 'supervisor', label: 'Supervisor', color: 'primary' },
  ],
  safety: [
    { value: 'inspector', label: 'Inspector', color: 'warning' },
    { value: 'coordinator', label: 'Coordinator', color: 'success' },
  ],
};
const NO_POSITIONS = [];

const FIELDS = [
  { id: 'name', label: 'Name', required: true },
  {
    id: 'site',
    label: 'Site',
    type: 'singleSelect',
    options: [
      { value: 'north', label: 'North plant' },
      { value: 'south', label: 'South plant' },
    ],
  },
  { id: 'zone', label: 'Zone', type: 'zone' },
  {
    id: 'area',
    label: 'Area',
    type: 'singleSelect',
    options: [
      { value: 'production', label: 'Production' },
      { value: 'safety', label: 'Safety' },
    ],
  },
  {
    id: 'position',
    label: 'Position',
    type: 'singleSelect',
    options: (record) => POSITIONS[record.area] ?? NO_POSITIONS,
  },
  { id: 'contractor', label: 'Contractor', type: 'checkbox' },
  {
    id: 'company',
    label: 'Company',
    readOnly: (record) => !record.contractor,
    required: (record) => record.contractor === true,
  },
];

const RECORDS = [
  { id: 'w1', name: 'Ana Ruiz', site: 'north', zone: { id: 'north-Offices', label: 'Offices' }, area: 'safety', position: 'inspector', contractor: false, company: '' },
  { id: 'w2', name: 'Bruno Vela', site: 'south', zone: { id: 'south-Paint line', label: 'Paint line' }, area: 'production', position: 'operator', contractor: true, company: 'Pinturas MX' },
  { id: 'w3', name: 'Carla Soto', site: 'south', zone: null, area: 'production', position: 'supervisor', contractor: true, company: '' },
  { id: 'w4', name: 'Diego Paz', site: 'north', zone: null, area: null, position: null, contractor: false, company: '' },
];

export default class SheetCustomCells extends Component {
  fieldTypes = { zone: zoneType };
  getId = (record) => record.id;
  store = localRecords(RECORDS, { getRecordId: this.getId, fields: FIELDS });

  <template>
    <EuiSheet
      @fields={{this.store.fields}}
      @records={{this.store.records}}
      @getRecordId={{this.getId}}
      @onChange={{this.store.apply}}
      @fieldTypes={{this.fieldTypes}}
      @height={{220}}
      @ariaLabel='Workers'
    />
  </template>
}
```
