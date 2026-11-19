/**
 * EuiSheetSearch (V02-DESIGN.md 7.2): an `EuiSheet` that shows an
 * EmberSearchUi driver's results through `SearchRecords`, with two default
 * controls: "Re-apply" in the toolbar while edits are shown over the last
 * results, and `EuiTablePagination` in the footer under offset paging.
 * An app that needs an `EuiSheet` argument this component does not forward
 * uses `searchRecords` with its own `<EuiSheet>`.
 */
import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { associateDestroyableChild, destroy } from '@ember/destroyable';
import { service } from '@ember/service';

import EuiButtonEmpty from '@ember-eui/core/components/eui-button-empty';
import EuiTablePagination from '@ember-eui/core/components/eui-table-pagination';

import EuiSheet from '../components/eui-sheet.gts';
import { createMessages } from '../core/index.ts';
import { fieldsFromSchema } from './fields-from-schema.ts';
import { searchRecords } from './search-records.ts';

import type { EuiSheetField, SheetMessages } from '../core/index.ts';
import type { EuiSheetSignature, SheetBlockApi } from '../types.ts';
import type {
  SearchRecords,
  SearchRecordsOptions,
  SheetSearchDriver
} from './search-records.ts';
import type EuiI18n from '@ember-eui/core/services/eui-i18n';

/** What the `<:toolbar>` and `<:footer>` blocks yield: the sheet's block API and the connector. */
export type SheetSearchBlockApi<Doc extends object> = SheetBlockApi<Doc> & {
  search: SearchRecords<Doc>;
};

/** The `EuiSheet` arguments the component passes on as they are. */
type ForwardedArgs<Doc> = Pick<
  EuiSheetSignature<Doc>['Args'],
  | 'hiddenFields'
  | 'onHiddenFieldsChange'
  | 'onFieldOrderChange'
  | 'fieldWidths'
  | 'onFieldWidthChange'
  | 'rowHeight'
  | 'onRowHeightChange'
  | 'frozenFields'
  | 'summary'
  | 'onFilterByField'
  | 'readOnly'
  | 'canInsert'
  | 'canDelete'
  | 'cellErrors'
  | 'validate'
  | 'fieldTypes'
  | 'messages'
  | 'height'
  | 'rowNumbers'
  | 'rowLabel'
  | 'rowActions'
  | 'newRecordValues'
  | 'expandedRecord'
  | 'expandedRecordId'
  | 'onExpandedRecordChange'
  | 'checkedRecordIds'
  | 'onCheckedChange'
  | 'registerApi'
  | 'ariaLabel'
  | 'onResolve'
  | 'editIn'
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
  };
}

const or = (a: unknown, b: unknown): boolean => Boolean(a) || Boolean(b);

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

  get reapplyLabel(): string {
    return (this.args.messages?.reapply ?? this.translatedMessages.reapply)();
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

  withSearch = (block: SheetBlockApi<Doc>): SheetSearchBlockApi<Doc> => ({
    ...block,
    search: this.search
  });

  <template>
    <EuiSheet
      class="euiSheetSearch"
      @fields={{this.fields}}
      @records={{this.search.records}}
      @getRecordId={{@getRecordId}}
      @onChange={{this.search.apply}}
      @sort={{this.search.sort}}
      @onSortChange={{this.search.setSort}}
      @highlight={{this.search.term}}
      @isLoading={{this.search.isLoading}}
      @rowNumberOffset={{this.search.rowNumberOffset}}
      @hiddenFields={{@hiddenFields}}
      @onHiddenFieldsChange={{@onHiddenFieldsChange}}
      @onFieldOrderChange={{@onFieldOrderChange}}
      @fieldWidths={{@fieldWidths}}
      @onFieldWidthChange={{@onFieldWidthChange}}
      @rowHeight={{@rowHeight}}
      @onRowHeightChange={{@onRowHeightChange}}
      @frozenFields={{@frozenFields}}
      @summary={{@summary}}
      @onFilterByField={{@onFilterByField}}
      @readOnly={{@readOnly}}
      @canInsert={{@canInsert}}
      @canDelete={{@canDelete}}
      @cellErrors={{@cellErrors}}
      @validate={{@validate}}
      @fieldTypes={{@fieldTypes}}
      @messages={{@messages}}
      @height={{@height}}
      @rowNumbers={{@rowNumbers}}
      @rowLabel={{@rowLabel}}
      @rowActions={{@rowActions}}
      @newRecordValues={{@newRecordValues}}
      @expandedRecord={{@expandedRecord}}
      @expandedRecordId={{@expandedRecordId}}
      @onExpandedRecordChange={{@onExpandedRecordChange}}
      @checkedRecordIds={{@checkedRecordIds}}
      @onCheckedChange={{@onCheckedChange}}
      @registerApi={{@registerApi}}
      @ariaLabel={{@ariaLabel}}
      @onResolve={{@onResolve}}
      @editIn={{@editIn}}
      ...attributes
    >
      <:toolbar as |sheet|>
        {{#if (or this.search.isStale (has-block "toolbar"))}}
          <div
            class="euiSheetSearch__bar"
            data-test-subj="euiSheetSearchToolbar"
          >
            {{#if this.search.isStale}}
              <EuiButtonEmpty
                @iconType="refresh"
                @size="s"
                data-test-subj="euiSheetSearchReapply"
                {{on "click" this.reapply}}
              >{{this.reapplyLabel}}</EuiButtonEmpty>
            {{/if}}
            {{yield (this.withSearch sheet) to="toolbar"}}
          </div>
        {{/if}}
      </:toolbar>
      <:footer as |sheet|>
        {{#if (or this.showPager (has-block "footer"))}}
          <div
            class="euiSheetSearch__footer"
            data-test-subj="euiSheetSearchFooter"
          >
            {{#if this.showPager}}
              <EuiTablePagination
                @activePage={{this.activePage}}
                @pageCount={{this.search.page.pageCount}}
                @itemsPerPage={{this.search.page.perPage}}
                @onChangePage={{this.changePage}}
                @onChangeItemsPerPage={{this.search.setPerPage}}
                data-test-subj="euiSheetSearchPagination"
              />
            {{/if}}
            {{yield (this.withSearch sheet) to="footer"}}
          </div>
        {{/if}}
      </:footer>
    </EuiSheet>
  </template>
}
