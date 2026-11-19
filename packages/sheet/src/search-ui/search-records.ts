/**
 * The EmberSearchUi connector's state (V02-DESIGN.md 7.2, 7.3): a driver's
 * results as `@records`, its query state as the sheet's intents, and the
 * user's change sets shown over the last results until the next search
 * ("stable + Re-apply"). It is written against `SheetSearchDriver`, the
 * part of `ember-search-ui-driver`'s `SearchDriver` it uses, and imports
 * nothing from EmberSearchUi.
 */
import { tracked } from '@glimmer/tracking';
import { registerDestructor } from '@ember/destroyable';
import { buildWaiter } from '@ember/test-waiters';

import { applyChangeSet } from '../core/index.ts';

import type { ChangeSet, RecordId } from '../core/index.ts';
import type { SheetSort } from '../types.ts';

const waiter = buildWaiter('@ember-eui/sheet:search-records');

/** The driver's page state: offset (1-based pages) or cursor paging. */
export type SheetSearchPage =
  | { readonly kind: 'offset'; readonly page: number; readonly perPage: number }
  | {
      readonly kind: 'cursor';
      readonly cursor: string | null;
      readonly size: number;
    };

/** The part of a driver snapshot the connector reads. */
export interface SheetSearchSnapshot<Doc = unknown> {
  readonly state: {
    readonly query: { readonly term: string };
    readonly sort: readonly SheetSort[];
    readonly page: SheetSearchPage;
  };
  readonly result: {
    readonly status: 'idle' | 'loading' | 'success' | 'error';
    readonly results: readonly Doc[];
    readonly total: number;
    readonly pageCount: number;
    readonly aggregations: Readonly<Record<string, unknown>>;
    readonly error?: unknown;
  };
}

/** One field of the driver's schema (`FieldDefinition`), as `fieldsFromSchema` reads it. */
export interface SheetSearchFieldDefinition {
  path: string;
  type: string;
  label?: string | undefined;
  /** The path is a list of objects: left out of the default fields. */
  nested?: boolean | undefined;
  options?:
    | readonly { value: string | number | boolean | null; label: string }[]
    | undefined;
}

/** The part of ember-search-ui-driver's `SearchDriver` the connector uses. */
export interface SheetSearchDriver<Doc = unknown> {
  readonly snapshot: SheetSearchSnapshot<Doc>;
  readonly schema?:
    Readonly<Record<string, SheetSearchFieldDefinition>> | undefined;
  /**
   * Optional (`SearchDriver` has both): with them the connector's test
   * waiter also covers the time between a command and the start of its
   * search (the driver's debounce timer).
   */
  readonly isSettled?: boolean;
  settled?(): Promise<void>;
  subscribe(
    listener: (snapshot: SheetSearchSnapshot<Doc>) => void,
    options?: { immediate?: boolean }
  ): () => void;
  setSort(sort: readonly SheetSort[]): void;
  setPage(page: number): void;
  setPerPage(perPage: number): void;
  refresh(): Promise<void>;
}

export interface SearchRecordsOptions<Doc> {
  getRecordId: (record: Doc) => RecordId;
  /** Persists a change set (an API call, or writing the memory backend's docs). May return a promise. */
  onChange: (changeSet: ChangeSet) => void | Promise<void>;
  /** For the rows shown before the next search. Default: `{ id: tempId, ...values }`. */
  createRecord?: (values: Record<string, unknown>, tempId: string) => Doc;
  /** Re-query after every change set instead of waiting for "Re-apply". Default false. */
  refreshOnChange?: boolean;
}

type Result<Doc> = SheetSearchSnapshot<Doc>['result'];
type State = SheetSearchSnapshot['state'];

function isPromise(value: unknown): value is Promise<unknown> {
  return (
    typeof value === 'object' &&
    value !== null &&
    typeof (value as { then?: unknown }).then === 'function'
  );
}

/**
 * A driver as sheet arguments. `records` are the last successful results
 * with the change sets applied since then: an edit shows at once and rows
 * do not move, vanish or re-sort until the next search (`reapply`, or any
 * search the driver runs), which replaces them.
 */
export class SearchRecords<Doc extends object> {
  readonly driver: SheetSearchDriver<Doc>;
  private readonly options: SearchRecordsOptions<Doc>;

  @tracked private snapshot: SheetSearchSnapshot<Doc>;
  @tracked private current: Doc[];
  @tracked private pending: readonly ChangeSet[] = [];
  /** The state the last successful result was searched with (its page). */
  @tracked private resultState: State | undefined;

  private lastResult: Result<Doc> | undefined;
  private readonly saving = new Set<Promise<unknown>>();
  private searchedWhileSaving = false;
  private reapplying = 0;
  private unsubscribe: (() => void) | undefined;
  private disconnected = false;
  private waiterToken: unknown;
  private awaitingSettle = false;
  private sortSource: readonly SheetSort[] | undefined;
  private sortCopy: SheetSort[] = [];

  constructor(
    driver: SheetSearchDriver<Doc>,
    options: SearchRecordsOptions<Doc>
  ) {
    this.driver = driver;
    this.options = options;
    const { snapshot } = driver;
    this.snapshot = snapshot;
    // a loading snapshot still holds the previous results: show them
    this.current = [...snapshot.result.results];
    if (snapshot.result.status === 'success') {
      this.lastResult = snapshot.result;
      this.resultState = snapshot.state;
    }
    this.unsubscribe = driver.subscribe(this.receive);
    this.updateWaiter();
  }

  /** The last results with the user's change sets since then applied on top. */
  get records(): Doc[] {
    return this.current;
  }

  /** The driver's sort (a copy that keeps its identity while the sort does not change). */
  get sort(): SheetSort[] {
    const source = this.snapshot.state.sort;
    if (source !== this.sortSource) {
      this.sortSource = source;
      this.sortCopy = source.map(({ field, direction }) => ({
        field,
        direction
      }));
    }
    return this.sortCopy;
  }

  /** The query text, for `@highlight`. */
  get term(): string {
    return this.snapshot.state.query.term;
  }

  get isLoading(): boolean {
    return this.snapshot.result.status === 'loading';
  }

  /** The last search's error, while the driver is in the error state. */
  get error(): unknown {
    const { result } = this.snapshot;
    return result.status === 'error' ? result.error : undefined;
  }

  get total(): number {
    return this.snapshot.result.total;
  }

  /** Offset paging only (the requested page); undefined under cursor paging. */
  get page(): { page: number; perPage: number; pageCount: number } | undefined {
    const { page } = this.snapshot.state;
    if (page.kind !== 'offset') return undefined;
    return {
      page: page.page,
      perPage: page.perPage,
      pageCount: this.snapshot.result.pageCount
    };
  }

  /**
   * `(page - 1) * perPage` of the page the shown results were searched
   * with (so the numbers change with the rows, not before them), or 0.
   */
  get rowNumberOffset(): number {
    const page = (this.resultState ?? this.snapshot.state).page;
    return page.kind === 'offset'
      ? Math.max(0, (page.page - 1) * page.perPage)
      : 0;
  }

  /** Edits were made since the last search: the rows may no longer match the query. */
  get isStale(): boolean {
    return this.pending.length > 0;
  }

  /** `@onChange`: shows the change set over the results and persists it. Does not re-query. */
  apply = (changeSet: ChangeSet): void => {
    this.pending = [...this.pending, changeSet];
    const { getRecordId, createRecord } = this.options;
    this.current = applyChangeSet(
      this.current,
      changeSet,
      createRecord ? { getRecordId, createRecord } : { getRecordId }
    );
    const saved = this.options.onChange(changeSet);
    if (isPromise(saved)) this.track(saved);
    if (this.options.refreshOnChange) void this.reapply();
  };

  /** `@onSortChange`: the driver's sort (it goes back to page 1). */
  setSort = (sort: SheetSort[]): void => {
    this.driver.setSort(sort);
    this.updateWaiter();
  };

  /** 1-based; does nothing under cursor paging. */
  setPage = (page: number): void => {
    if (this.snapshot.state.page.kind !== 'offset') return;
    this.driver.setPage(page);
    this.updateWaiter();
  };

  setPerPage = (perPage: number): void => {
    this.driver.setPerPage(perPage);
    this.updateWaiter();
  };

  /** Waits for pending `onChange` promises, then `driver.refresh()`. */
  reapply = async (): Promise<void> => {
    this.reapplying++;
    try {
      while (this.saving.size) await Promise.allSettled([...this.saving]);
    } finally {
      this.reapplying--;
    }
    // this refresh is the one a search during the save would have needed
    this.searchedWhileSaving = false;
    if (this.disconnected) return;
    await this.driver.refresh();
  };

  /** Stops listening to the driver (it is not destroyed). `searchRecords` calls it when its owner is destroyed. */
  disconnect(): void {
    this.disconnected = true;
    this.unsubscribe?.();
    this.unsubscribe = undefined;
    this.endWaiter();
  }

  private receive = (snapshot: SheetSearchSnapshot<Doc>): void => {
    this.snapshot = snapshot;
    const { result } = snapshot;
    // State-only changes re-emit the same result object, and a loading or
    // error snapshot keeps the previous results: only a new successful
    // result replaces the rows and drops the overlay.
    if (result.status === 'success' && result !== this.lastResult) {
      this.lastResult = result;
      this.resultState = snapshot.state;
      this.current = [...result.results];
      this.pending = [];
      if (this.saving.size) this.searchedWhileSaving = true;
    }
    this.updateWaiter();
    // a command's search starts on the driver's timer, set after this emit
    if (this.driver.isSettled !== undefined) {
      queueMicrotask(() => this.updateWaiter());
    }
  };

  private track(promise: Promise<unknown>): void {
    this.saving.add(promise);
    this.updateWaiter();
    const done = () => {
      this.saving.delete(promise);
      if (
        !this.saving.size &&
        this.searchedWhileSaving &&
        !this.reapplying &&
        !this.disconnected
      ) {
        // a search finished while the change was being saved: its results
        // may not have it
        this.searchedWhileSaving = false;
        void this.driver.refresh();
      }
      this.updateWaiter();
    };
    promise.then(done, (error: unknown) => {
      done();
      // the change set stays in the overlay; the app's error handling gets it
      throw error;
    });
  }

  private updateWaiter(): void {
    const settledFlag = this.driver.isSettled;
    const busy =
      !this.disconnected &&
      (this.snapshot.result.status === 'loading' ||
        this.saving.size > 0 ||
        settledFlag === false);
    if (busy && !this.waiterToken) {
      this.waiterToken = waiter.beginAsync();
    } else if (!busy) {
      this.endWaiter();
    }
    if (busy && settledFlag === false && this.driver.settled) {
      if (this.awaitingSettle) return;
      this.awaitingSettle = true;
      void this.driver.settled().then(() => {
        this.awaitingSettle = false;
        this.updateWaiter();
      });
    }
  }

  private endWaiter(): void {
    if (this.waiterToken) {
      waiter.endAsync(this.waiterToken);
      this.waiterToken = undefined;
    }
  }
}

/** The driver as sheet arguments, tied to `owner`'s lifetime (unsubscribes on destroy; never destroys the driver). */
export function searchRecords<Doc extends object>(
  owner: object,
  driver: SheetSearchDriver<Doc>,
  options: SearchRecordsOptions<Doc>
): SearchRecords<Doc> {
  const search = new SearchRecords(driver, options);
  registerDestructor(owner, () => search.disconnect());
  return search;
}
