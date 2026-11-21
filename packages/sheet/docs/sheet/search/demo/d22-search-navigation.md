---
order: 1
---

# Search navigation

<EuiText>

The sheet does not search: the app does, and passes the term as
`@highlight` and its current match as `@currentMatch`. When the match
changes the sheet scrolls it into view (below the header, clear of the
frozen field) and draws a ring around it, without taking focus from the
search box, so you can keep typing. This app holds every record, so it
lists the matches with the core's `findMatches` (the cells whose shown
text contains the term, by row then field, as `@highlight` marks them)
and keeps an index; an app that pages gets its matches from its
backend.

Try: type `ana` in the box (focus stays there while the ring moves),
then Enter and Shift+Enter to step forwards and backwards; the steps
wrap. Matches are far down (300 records) and far right (the Notes and
Code fields): the grid scrolls to each one, clear of the frozen Name
field. Turn on "Group by team", collapse a team with its chevron, and
step to one of its matches: the app expands that group first (a match
in a collapsed group is not in `@records`, so the sheet would draw
nothing). Escape in the box focuses the current match's cell
(`api.focusCell`), for editing it.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import {
  EuiButtonIcon,
  EuiFieldText,
  EuiFlexGroup,
  EuiFlexItem,
  EuiSwitch,
  EuiText,
} from '@ember-eui/core/components';
import { EuiSheet, builtInFieldTypes, defaultMessages, findMatches, groupRecords, localRecords } from '@ember-eui/sheet';

const NAMES = ['Alba', 'Bruno', 'Carla', 'Diego', 'Elena', 'Fabián', 'Gael', 'Hugo', 'Iván', 'Julia'];
const TEAMS = ['North', 'South', 'East', 'West'];
const CITIES = ['Monterrey', 'Madrid', 'Lima', 'Santiago', 'Bogotá'];

const FIELDS = [
  { id: 'name', label: 'Name', width: 150 },
  { id: 'team', label: 'Team', width: 120 },
  { id: 'city', label: 'City', width: 140 },
  { id: 'hours', label: 'Hours', type: 'number', width: 100 },
  { id: 'start', label: 'Start', type: 'date', width: 130 },
  { id: 'mentor', label: 'Mentor', width: 150 },
  { id: 'notes', label: 'Notes', width: 320 },
  { id: 'code', label: 'Code', width: 140 },
];

// about twenty "ana", some far down and some far right
const RECORDS = Array.from({ length: 300 }, (_, i) => ({
  id: `p${i + 1}`,
  name: i % 41 === 7 ? `Ana Ruiz ${i + 1}` : `${NAMES[(i * 7) % NAMES.length]} ${i + 1}`,
  team: TEAMS[i % TEAMS.length],
  city: CITIES[(i * 3) % CITIES.length],
  hours: (i * 13) % 40,
  start: `2026-${String(1 + (i % 12)).padStart(2, '0')}-${String(1 + ((i * 5) % 28)).padStart(2, '0')}`,
  mentor: i % 73 === 5 ? 'Mariana Ruiz' : NAMES[(i * 3 + 1) % NAMES.length],
  notes: i % 53 === 20 ? 'Ask Ana about the handover' : '',
  code: i === 287 ? 'BANANA-7' : `C-${1000 + i}`,
}));

const CONTEXT = { types: builtInFieldTypes, messages: defaultMessages, getRecordId: (record) => record.id };

export default class SheetSearchNavigation extends Component {
  getId = (record) => record.id;
  store = localRecords(RECORDS, { getRecordId: this.getId, fields: FIELDS });
  api = null;

  @tracked term = 'ana';
  @tracked index = 0;

  get grouped() {
    return this.store.groupBy.length > 0;
  }

  /** Every record in display order, collapsed groups' too. */
  get shown() {
    return groupRecords(CONTEXT, this.store.records, { groupBy: this.store.groupBy, fields: FIELDS });
  }

  get matches() {
    return findMatches(CONTEXT, this.shown.records, FIELDS, this.term);
  }

  get currentMatch() {
    return this.matches[this.index] ?? null;
  }

  get position() {
    const count = this.matches.length;
    if (!this.term) return '';
    return count ? `${this.index + 1} of ${count}` : 'No matches';
  }

  /** The keys of a record's group and its parents (groupRecords' leaf groups take their records in order). */
  groupKeysOf(recordId) {
    let i = 0;
    const { records, groups } = this.shown;
    for (const group of groups) {
      for (let n = 0; n < (group.loaded ?? 0); n++) {
        if (records[i++].id === recordId) {
          const parts = group.key.split('/');
          return parts.map((_, depth) => parts.slice(0, depth + 1).join('/'));
        }
      }
    }
    return [];
  }

  step(by) {
    const count = this.matches.length;
    if (!count) return;
    this.index = (this.index + by + count) % count;
    // a match in a collapsed group: expand it first
    for (const key of this.groupKeysOf(this.matches[this.index].recordId)) {
      if (this.store.collapsedGroups.has(key)) this.store.toggleGroup(key, false);
    }
  }

  previous = () => this.step(-1);
  next = () => this.step(1);

  onInput = (event) => {
    this.term = event.target.value;
    this.index = 0;
  };

  onKeyDown = (event) => {
    if (event.key === 'Enter') {
      event.preventDefault();
      this.step(event.shiftKey ? -1 : 1);
    } else if (event.key === 'Escape' && this.currentMatch) {
      event.preventDefault();
      this.api?.focusCell(this.currentMatch);
    }
  };

  toggleGrouped = (event) => {
    this.store.setGroupBy(event.target.checked ? [{ field: 'team', direction: 'asc' }] : []);
    this.index = 0;
  };

  registerApi = (api) => (this.api = api);

  <template>
    <EuiSheet
      @fields={{this.store.fields}}
      @records={{this.store.view.records}}
      @groups={{this.store.view.groups}}
      @groupBy={{this.store.groupBy}}
      @onGroupToggle={{this.store.toggleGroup}}
      @getRecordId={{this.getId}}
      @onChange={{this.store.apply}}
      @highlight={{this.term}}
      @currentMatch={{this.currentMatch}}
      @frozenFields={{1}}
      @registerApi={{this.registerApi}}
      @height={{360}}
      @ariaLabel='People'
    >
      <:toolbar>
        <EuiFlexGroup @gutterSize='s' @alignItems='center' @responsive={{false}} @wrap={{true}}>
          <EuiFlexItem @grow={{false}}>
            <EuiFieldText
              @value={{this.term}}
              @placeholder='Search'
              @icon='search'
              @compressed={{true}}
              aria-label='Search the sheet'
              data-test-subj='sheetSearch'
              {{on 'input' this.onInput}}
              {{on 'keydown' this.onKeyDown}}
            />
          </EuiFlexItem>
          <EuiFlexItem @grow={{false}}>
            <EuiText @size='xs' @color='subdued' data-test-subj='sheetSearchPosition'>{{this.position}}</EuiText>
          </EuiFlexItem>
          <EuiFlexItem @grow={{false}}>
            <EuiButtonIcon
              @iconType='arrowLeft'
              @size='s'
              aria-label='Previous match'
              data-test-subj='sheetSearchPrevious'
              {{on 'click' this.previous}}
            />
          </EuiFlexItem>
          <EuiFlexItem @grow={{false}}>
            <EuiButtonIcon
              @iconType='arrowRight'
              @size='s'
              aria-label='Next match'
              data-test-subj='sheetSearchNext'
              {{on 'click' this.next}}
            />
          </EuiFlexItem>
          <EuiFlexItem @grow={{false}}>
            <EuiSwitch
              @label='Group by team'
              @checked={{this.grouped}}
              @compressed={{true}}
              @onChange={{this.toggleGrouped}}
            />
          </EuiFlexItem>
        </EuiFlexGroup>
      </:toolbar>
    </EuiSheet>
  </template>
}
```

An owner with its own search box does the same with any source of
matches: keep the list and an index, pass `matches[index]` as
`@currentMatch`, and step on Enter. `api.scrollToCell(cell)` scrolls
without the ring; `api.focusCell(cell)` moves focus there (for when the
user leaves the box). A match that is not in `@records` (another page,
a collapsed group) or in a hidden field draws nothing until the owner
shows it.
