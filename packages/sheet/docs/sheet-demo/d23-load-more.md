---
order: 23
---

# Load more as you scroll

<EuiText>

No pager: the first 100 of 1,000 records load, and scrolling near the end
loads the next 100. The sheet only says which records are on screen:
`@onVisibleRangeChange` gets `{ first, last, count }` (positions in
`@records`) after each render that changed them. The owner decides: here,
when `last` is within 20 of `count`, nothing is loading and more is left,
it fetches the next page (a fake server that takes 800 ms), shows
`@isLoading` meanwhile and appends to `@records`. The scroll position,
the selection and the focused cell stay where they are. Scrolling to the
end again while a page is loading starts no second load: the owner's own
`isLoading` guards it. The add row appears once everything is loaded.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { EuiText } from '@ember-eui/core/components';
import { EuiSheet, localRecords } from '@ember-eui/sheet';

const TEAMS = [
  { value: 'ops', label: 'Operations', color: 'primary' },
  { value: 'hse', label: 'Safety', color: 'success' },
  { value: 'qa', label: 'Quality', color: 'warning' },
  { value: 'it', label: 'IT', color: 'accent' },
];

const FIELDS = [
  { id: 'code', label: 'Code', readOnly: true, width: 110 },
  { id: 'name', label: 'Name', required: true },
  { id: 'team', label: 'Team', type: 'singleSelect', options: TEAMS },
  { id: 'hours', label: 'Hours', type: 'number', min: 0 },
  { id: 'start', label: 'Start', type: 'date' },
];

const TOTAL = 1000;
const PAGE = 100;

/** Records `from` to `from + count - 1` of the fake server. */
function page(from, count) {
  return Array.from({ length: count }, (_, k) => {
    const i = from + k;
    return {
      id: i + 1,
      code: `E-${String(i + 1).padStart(4, '0')}`,
      name: `Employee ${i + 1}`,
      team: TEAMS[i % TEAMS.length].value,
      hours: (i * 7) % 41,
      start: `2026-${String(1 + (i % 12)).padStart(2, '0')}-${String(1 + (i % 28)).padStart(2, '0')}`,
    };
  });
}

/** The fake server: the next page after a delay. */
function fetchPage(from) {
  return new Promise((resolve) =>
    setTimeout(() => resolve(page(from, Math.min(PAGE, TOTAL - from))), 800)
  );
}

export default class SheetLoadMore extends Component {
  getId = (record) => record.id;
  store = localRecords(page(0, PAGE), { getRecordId: this.getId });

  @tracked isLoading = false;
  @tracked loads = 1;
  /** Fetches started: one per page, never two at once. */
  @tracked requests = 0;
  @tracked range = null;

  get hasMore() {
    return this.store.records.length < TOTAL;
  }

  get canInsert() {
    return !this.hasMore;
  }

  get status() {
    const loaded = this.store.records.length;
    const range = this.range;
    const view = range ? ` · records ${range.first + 1}–${range.last + 1} in view` : '';
    return `${loaded} of ${TOTAL} loaded in ${this.loads} ${this.loads === 1 ? 'page' : 'pages'}${view}`;
  }

  onVisibleRangeChange = (range) => {
    this.range = range;
    const { last, count } = range;
    if (this.hasMore && !this.isLoading && last >= count - 20) this.loadMore();
  };

  async loadMore() {
    this.isLoading = true;
    this.requests++;
    const more = await fetchPage(this.store.records.length);
    if (this.isDestroying || this.isDestroyed) return;
    this.store.records = [...this.store.records, ...more];
    this.loads++;
    this.isLoading = false;
  }

  <template>
    <EuiSheet
      @fields={{FIELDS}}
      @records={{this.store.records}}
      @getRecordId={{this.getId}}
      @onChange={{this.store.apply}}
      @onVisibleRangeChange={{this.onVisibleRangeChange}}
      @isLoading={{this.isLoading}}
      @canInsert={{this.canInsert}}
      @height={{400}}
      @ariaLabel='Employees'
    >
      <:footer>
        <EuiText @size='xs' @color='subdued' data-test-subj='loadMoreStatus' data-requests={{this.requests}}>
          {{this.status}}{{if this.isLoading ' · loading…'}}
        </EuiText>
      </:footer>
    </EuiSheet>
  </template>
}
```
