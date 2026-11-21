/**
 * EuiSheetSearch (V02-DESIGN.md 7.2): an `EuiSheet` that shows an
 * EmberSearchUi driver's results through `SearchRecords`, with two default
 * controls: "Re-apply" in the toolbar while edits are shown over the last
 * results, and `EuiTablePagination` in the footer under offset paging.
 * Every other `EuiSheet` argument and block is passed on as it is (the
 * search owns `@records`, `@sort`, `@onSortChange`, `@highlight`,
 * `@isLoading` and `@rowNumberOffset`); an app that needs more control
 * uses `searchRecords` with its own `<EuiSheet>`.
 */
import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { associateDestroyableChild, destroy } from '@ember/destroyable';
import { service } from '@ember/service';

import EuiButton from '@ember-eui/core/components/eui-button';
import EuiTablePagination from '@ember-eui/core/components/eui-table-pagination';

import EuiSheet from '../components/eui-sheet.gts';
import { createMessages } from '../core/index.ts';
import { fieldsFromSchema } from './fields-from-schema.ts';
import { searchRecords } from './search-records.ts';

import type {
  EuiSheetField,
  SheetGroup,
  SheetMessages
} from '../core/index.ts';
import type { EuiSheetSignature, SheetBlockApi } from '../types.ts';
import type {
  SearchRecords,
  SearchRecordsOptions,
  SheetSearchDriver
} from './search-records.ts';
import type EuiI18n from '@ember-eui/core/services/eui-i18n';
import type { TOC } from '@ember/component/template-only';

/** What the `<:toolbar>` and `<:footer>` blocks yield: the sheet's block API and the connector. */
export type SheetSearchBlockApi<Doc extends object> = SheetBlockApi<Doc> & {
  search: SearchRecords<Doc>;
};

/** The `EuiSheet` arguments the search provides (`SearchRecords`), or the component's own arguments replace. */
type SheetSearchOwnedArg =
  | 'fields'
  | 'records'
  | 'getRecordId'
  | 'onChange'
  | 'sort'
  | 'onSortChange'
  | 'highlight'
  | 'isLoading'
  | 'rowNumberOffset'
  | 'groups';

/** The `EuiSheet` arguments the component passes on as they are: all the others. */
type ForwardedArgs<Doc> = Omit<
  EuiSheetSignature<Doc>['Args'],
  SheetSearchOwnedArg
>;

export interface EuiSheetSearchSignature<Doc extends object> {
  Element: HTMLDivElement;
  Args: ForwardedArgs<Doc> & {
    /** An EmberSearchUi `SearchDriver` (or anything with the same members). Never destroyed by the component. */
    driver: SheetSearchDriver<Doc>;
    getRecordId: SearchRecordsOptions<Doc>['getRecordId'];
    /** Persists a change set; may return a promise. The rows show it at once and the driver is not re-queried. */
    onChange: SearchRecordsOptions<Doc>['onChange'];
    createRecord?: SearchRecordsOptions<Doc>['createRecord'];
    /** Re-query after every change set instead of showing "Re-apply". Default false. */
    refreshOnChange?: boolean;
    /**
     * The group headers (V03 8.8). An array is passed to the sheet as it
     * is. A function gets each new successful snapshot and returns the
     * headers; the connector then keeps them in step with the user's
     * edits until "Re-apply", as it does the rows (`SearchRecords.groups`).
     */
    groups?: SheetGroup[] | NonNullable<SearchRecordsOptions<Doc>['groups']>;
    /** Default: `fieldsFromSchema(driver.schema)`. */
    fields?: EuiSheetField<Doc>[];
    /** Shows `EuiTablePagination` in the footer under offset paging. Default true. */
    paging?: boolean;
  };
  Blocks: {
    /** After the "Re-apply" button. */
    toolbar: [SheetSearchBlockApi<Doc>];
    /** After the pagination. */
    footer: [SheetSearchBlockApi<Doc>];
    /** As `EuiSheet`'s: replaces the "No records" message. */
    empty: [SheetSearchBlockApi<Doc>];
    /** As `EuiSheet`'s: below the expanded record's fields. */
    recordFooter: [Doc, SheetSearchBlockApi<Doc>];
  };
}

const or = (a: unknown, b: unknown): boolean => Boolean(a) || Boolean(b);

interface SearchBarSignature {
  Args: {
    connector: EuiSheetSearch<any>;
    /** The app gave the connector this block (it is the yielded content). */
    hasBlock: boolean;
  };
  Blocks: { default: [] };
}

/** The toolbar's content: "Re-apply" while the results are stale, then the app's block. */
const SearchToolbar: TOC<SearchBarSignature> = <template>
  {{#if (or @connector.search.isStale @hasBlock)}}
    <div class="euiSheetSearch__bar" data-test-subj="euiSheetSearchToolbar">
      {{#if @connector.search.isStale}}
        {{! a small primary button: stale results must be noticed (V03 batch 2) }}
        <EuiButton
          @iconType="refresh"
          @size="s"
          @color="primary"
          data-test-subj="euiSheetSearchReapply"
          {{on "click" @connector.reapply}}
        >{{@connector.reapplyLabel}}</EuiButton>
      {{/if}}
      {{yield}}
    </div>
  {{/if}}
</template>;

/** The footer's content: the pagination under offset paging, then the app's block. */
const SearchFooter: TOC<SearchBarSignature> = <template>
  {{#if (or @connector.showPager @hasBlock)}}
    <div class="euiSheetSearch__footer" data-test-subj="euiSheetSearchFooter">
      {{#if @connector.showPager}}
        <EuiTablePagination
          @activePage={{@connector.activePage}}
          @pageCount={{@connector.search.page.pageCount}}
          @itemsPerPage={{@connector.search.page.perPage}}
          @onChangePage={{@connector.changePage}}
          @onChangeItemsPerPage={{@connector.search.setPerPage}}
          data-test-subj="euiSheetSearchPagination"
        />
      {{/if}}
      {{yield}}
    </div>
  {{/if}}
</template>;

export default class EuiSheetSearch<Doc extends object> extends Component<
  EuiSheetSearchSignature<Doc>
> {
  @service('eui-i18n') declare euiI18n: EuiI18n;

  private connection:
    | {
        driver: SheetSearchDriver<Doc>;
        scope: object;
        search: SearchRecords<Doc>;
      }
    | undefined;

  translatedMessages: SheetMessages = createMessages((token, def, values) =>
    this.euiI18n.lookupToken(token, def, values)
  );

  /** Options that read the current arguments at each call. */
  private options: SearchRecordsOptions<Doc> = ((component) => ({
    getRecordId: (record: Doc) => component.args.getRecordId(record),
    onChange: (changeSet) => component.args.onChange(changeSet),
    createRecord: (values: Record<string, unknown>, tempId: string): Doc =>
      component.args.createRecord
        ? component.args.createRecord(values, tempId)
        : ({ id: tempId, ...values } as unknown as Doc),
    get refreshOnChange() {
      return component.args.refreshOnChange ?? false;
    },
    get groups() {
      const { groups } = component.args;
      return typeof groups === 'function' ? groups : undefined;
    }
  }))(this);

  /** The connector for `@driver` (a new `@driver` connects again; the old one is only unsubscribed). */
  /* eslint-disable ember/no-side-effects */
  get search(): SearchRecords<Doc> {
    const { driver } = this.args;
    if (this.connection?.driver !== driver) {
      if (this.connection) destroy(this.connection.scope);
      const scope = {};
      associateDestroyableChild(this, scope);
      this.connection = {
        driver,
        scope,
        search: searchRecords(scope, driver, this.options)
      };
    }
    return this.connection.search;
  }
  /* eslint-enable ember/no-side-effects */

  @cached
  get fields(): EuiSheetField<Doc>[] {
    return (
      this.args.fields ??
      (fieldsFromSchema(this.args.driver.schema) as EuiSheetField<Doc>[])
    );
  }

  /** `@groups` as an array, or the connector's copy of what the function returned. */
  get groups(): SheetGroup[] | undefined {
    const { groups } = this.args;
    return typeof groups === 'function' ? this.search.groups : groups;
  }

  get reapplyLabel(): string {
    return (this.args.messages?.reapply ?? this.translatedMessages.reapply)();
  }

  /** The sheet's own "No records" (the `<:empty>` block is always passed on). */
  get noRecordsLabel(): string {
    return (
      this.args.messages?.noRecords ?? this.translatedMessages.noRecords
    )();
  }

  get showPager(): boolean {
    return this.args.paging !== false && this.search.page !== undefined;
  }

  /** EuiTablePagination's pages are 0-based; the driver's are 1-based. */
  get activePage(): number {
    return Math.max(0, (this.search.page?.page ?? 1) - 1);
  }

  changePage = (index: number): void => this.search.setPage(index + 1);

  /**
   * The result removes the button. When it has focus, focus goes back to
   * the grid's current cell first (its tab stop), so the sheet moves it
   * with that cell's record instead of losing it to the page.
   */
  reapply = (event: Event): void => {
    const button = event.currentTarget as HTMLElement | null;
    if (button && document.activeElement === button) {
      button
        .closest('.euiSheet')
        ?.querySelector<HTMLElement>(
          '[role=gridcell][tabindex="0"], [role=columnheader][tabindex="0"]'
        )
        ?.focus();
    }
    void this.search.reapply();
  };

  /** `EuiSheet` with this component's record type, for `(component)`. */
  Sheet = EuiSheet<Doc>;

  withSearch = (block: SheetBlockApi<Doc>): SheetSearchBlockApi<Doc> => ({
    ...block,
    search: this.search
  });

  <template>
    {{! every argument once: the two invocations below differ only in <:recordFooter> (EuiSheet draws its divider when the block is given) }}
    {{#let
      (component
        this.Sheet
        fields=this.fields
        records=this.search.records
        getRecordId=@getRecordId
        onChange=this.search.apply
        sort=this.search.sort
        onSortChange=this.search.setSort
        highlight=this.search.term
        isLoading=this.search.isLoading
        rowNumberOffset=this.search.rowNumberOffset
        groups=this.groups
        cellErrors=@cellErrors
        height=@height
        fieldTypes=@fieldTypes
        readOnly=@readOnly
        messages=@messages
        ariaLabel=@ariaLabel
        validate=@validate
        registerApi=@registerApi
        hiddenFields=@hiddenFields
        onHiddenFieldsChange=@onHiddenFieldsChange
        onFieldOrderChange=@onFieldOrderChange
        fieldDrag=@fieldDrag
        headerLines=@headerLines
        onFieldCreate=@onFieldCreate
        onFieldUpdate=@onFieldUpdate
        onFieldDelete=@onFieldDelete
        fieldEditor=@fieldEditor
        creatableFieldTypes=@creatableFieldTypes
        fieldWidths=@fieldWidths
        onFieldWidthChange=@onFieldWidthChange
        rowHeight=@rowHeight
        onRowHeightChange=@onRowHeightChange
        onFilterByField=@onFilterByField
        currentMatch=@currentMatch
        onSelectionChange=@onSelectionChange
        onVisibleRangeChange=@onVisibleRangeChange
        fullScreen=@fullScreen
        onFullScreenChange=@onFullScreenChange
        summary=@summary
        frozenFields=@frozenFields
        rowNumbers=@rowNumbers
        rowLabel=@rowLabel
        groupBy=@groupBy
        onGroupByChange=@onGroupByChange
        onGroupToggle=@onGroupToggle
        canInsert=@canInsert
        canDelete=@canDelete
        canMove=@canMove
        rowColor=@rowColor
        cellColor=@cellColor
        onButtonPress=@onButtonPress
        newRecordValues=@newRecordValues
        checkedRecordIds=@checkedRecordIds
        onCheckedChange=@onCheckedChange
        expandedRecordId=@expandedRecordId
        onExpandedRecordChange=@onExpandedRecordChange
        expandedRecord=@expandedRecord
        rowActions=@rowActions
        fieldActions=@fieldActions
        copyWithFieldNames=@copyWithFieldNames
        onResolve=@onResolve
        editIn=@editIn
      )
      as |Sheet|
    }}
      {{#if (has-block "recordFooter")}}
        <Sheet class="euiSheetSearch" ...attributes>
          <:toolbar as |sheet|>
            <SearchToolbar
              @connector={{this}}
              @hasBlock={{has-block "toolbar"}}
            >{{yield (this.withSearch sheet) to="toolbar"}}</SearchToolbar>
          </:toolbar>
          <:footer as |sheet|>
            <SearchFooter
              @connector={{this}}
              @hasBlock={{has-block "footer"}}
            >{{yield (this.withSearch sheet) to="footer"}}</SearchFooter>
          </:footer>
          <:empty as |sheet|>
            {{#if (has-block "empty")}}
              {{yield (this.withSearch sheet) to="empty"}}
            {{else}}
              <span role="status">{{this.noRecordsLabel}}</span>
            {{/if}}
          </:empty>
          <:recordFooter as |record sheet|>
            {{yield record (this.withSearch sheet) to="recordFooter"}}
          </:recordFooter>
        </Sheet>
      {{else}}
        <Sheet class="euiSheetSearch" ...attributes>
          <:toolbar as |sheet|>
            <SearchToolbar
              @connector={{this}}
              @hasBlock={{has-block "toolbar"}}
            >{{yield (this.withSearch sheet) to="toolbar"}}</SearchToolbar>
          </:toolbar>
          <:footer as |sheet|>
            <SearchFooter
              @connector={{this}}
              @hasBlock={{has-block "footer"}}
            >{{yield (this.withSearch sheet) to="footer"}}</SearchFooter>
          </:footer>
          <:empty as |sheet|>
            {{#if (has-block "empty")}}
              {{yield (this.withSearch sheet) to="empty"}}
            {{else}}
              <span role="status">{{this.noRecordsLabel}}</span>
            {{/if}}
          </:empty>
        </Sheet>
      {{/if}}
    {{/let}}
  </template>
}
