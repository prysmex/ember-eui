import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { schedule } from '@ember/runloop';

import { modifier } from 'ember-modifier';
import { provide } from 'ember-provide-consume-context';

import {
  DEFAULT_TABLE_BREAKPOINT,
  EUI_TABLE_CONTEXT,
  TABLE_RESET,
  isTableResponsive,
  minBreakpointQuery,
  onMediaQueryChange
} from '../-private/table.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import type { EuiCss } from '../utils/eui/styles.ts';
import {
  EUI_TABLE_CSS_CONTAINER_NAME,
  euiContainerCSS,
  euiTableStyles
} from '../utils/eui/styles.generated.ts';
import EuiTableStickyHeader from './eui-table/sticky-header.gts';
import EuiTableStickyScrollbar, {
  StickyScrollbarState
} from './eui-table/sticky-scrollbar.gts';

import type {
  EuiTableContext,
  StickyHeaderCellSync,
  TableResponsiveBreakpoint
} from '../-private/table.ts';
import type { StickyHeaderHost } from './eui-table/sticky-header.gts';

/**
 * A styled `<table>`, built from `EuiTableHeader`, `EuiTableHeaderCell`,
 * `EuiTableBody`, `EuiTableRow` and `EuiTableRowCell`. These components
 * only render the markup: sorting, selection and pagination stay yours
 * (or come from a headless table library).
 *
 * Like upstream, the table is wrapped in a `div.euiTable__wrapper`;
 * attributes go to the `<table>`. `@stickyHeader` renders a copy of the
 * header before the wrapper, and `@stickyScrollbar` a scrollbar after it.
 */
export interface EuiTableSignature {
  Element: HTMLTableElement;
  Args: {
    /**
     * Extra styles composed last into the `<table>`'s class (like upstream's
     * `css` prop). Prefer this to an extra class when styling it from a parent.
     */
    css?: EuiCss;
    /** Smaller text and padding (not applied to the cards layout). */
    compressed?: boolean;
    /**
     * `'fixed'` (columns share the width, text wraps or truncates) or
     * `'auto'` (columns fit their content). Defaults to `'fixed'`.
     */
    tableLayout?: 'fixed' | 'auto';
    /**
     * Rows become cards below `@responsiveBreakpoint`. Defaults to `true`;
     * `false` never collapses (same as `@responsiveBreakpoint={{false}}`).
     */
    responsive?: boolean;
    /**
     * Named theme breakpoint below which rows become cards; `true` always
     * renders cards, `false` never. Defaults to `'m'` (upstream). Takes
     * precedence over `@responsive`.
     */
    responsiveBreakpoint?: TableResponsiveBreakpoint;
    /** The table's plain background. Defaults to `true`. */
    hasBackground?: boolean;
    /**
     * Lets the table grow wider than its container and scroll inline.
     * Use with `@tableLayout="auto"`. Upstream beta.
     */
    scrollableInline?: boolean;
    /**
     * Shows a horizontal scrollbar sticking to the bottom of the viewport
     * while the table's own one is out of view (long tables). Requires
     * `@scrollableInline`. Upstream beta.
     */
    stickyScrollbar?: boolean;
    /**
     * Keeps the header at the top of the viewport while the user scrolls
     * through a long table (not in the cards layout). Offset it with the
     * `--euiTableStickyHeaderOffsetTop` CSS variable (e.g. below a fixed
     * header) and layer it with `--euiTableStickyHeaderZIndex`. Upstream
     * beta.
     */
    stickyHeader?: boolean;
  };
  Blocks: {
    /** The header, body and footer. */
    default: [];
  };
}

/**
 * The sticky header row of each table, created once: the sticky header
 * attaches it and header cells render their copies into it.
 */
const STICKY_ROWS = new WeakMap<object, HTMLTableRowElement>();
function stickyRowOf(table: object): HTMLTableRowElement {
  let row = STICKY_ROWS.get(table);
  if (!row) STICKY_ROWS.set(table, (row = document.createElement('tr')));
  return row;
}

const WRAPPER_CONTAINER = euiContainerCSS(
  'normal',
  EUI_TABLE_CSS_CONTAINER_NAME,
  true
);

export default class EuiTable
  extends Component<EuiTableSignature>
  implements EuiTableContext, StickyHeaderHost
{
  /** Bumped when the breakpoint query starts or stops matching. */
  @tracked private mediaVersion = 0;

  // Elements of the sticky header and scrollbar (DOM refs, not state).
  tableElement?: HTMLTableElement;
  stickyContainer?: HTMLElement;
  stickyTable?: HTMLTableElement;
  private stickyCells = new Set<StickyHeaderCellSync>();
  private reorderScheduled = false;
  stickyScrollbar = new StickyScrollbarState();

  @provide(EUI_TABLE_CONTEXT)
  get tableContext(): EuiTableContext {
    return this;
  }

  get responsiveBreakpoint(): TableResponsiveBreakpoint {
    const { responsiveBreakpoint, responsive } = this.args;
    if (responsiveBreakpoint !== undefined) return responsiveBreakpoint;
    return responsive === false ? false : DEFAULT_TABLE_BREAKPOINT;
  }

  @cached
  get query(): string | undefined {
    return minBreakpointQuery(
      getEuiThemeContext(this).upstream,
      this.responsiveBreakpoint
    );
  }

  @cached
  get isResponsive(): boolean {
    // consumed so the media query listener can invalidate this getter
    void this.mediaVersion;
    return isTableResponsive(this.responsiveBreakpoint, this.query);
  }

  get hasBackground(): boolean {
    return this.args.hasBackground ?? true;
  }

  onBreakpointChange = (): void => {
    this.mediaVersion++;
  };

  /** Upstream renders the sticky header only outside the cards layout. */
  get showStickyHeader(): boolean {
    return Boolean(this.args.stickyHeader) && !this.isResponsive;
  }

  get showStickyScrollbar(): boolean {
    return Boolean(this.args.scrollableInline && this.args.stickyScrollbar);
  }

  get stickyHeaderRow(): HTMLTableRowElement | undefined {
    if (!this.showStickyHeader || typeof document === 'undefined') {
      return undefined;
    }
    return stickyRowOf(this);
  }

  private get stickyRow(): HTMLTableRowElement | undefined {
    return STICKY_ROWS.get(this);
  }

  registerStickyHeaderCell = (cell: StickyHeaderCellSync): (() => void) => {
    this.stickyCells.add(cell);
    this.scheduleStickyReorder();
    return () => {
      this.stickyCells.delete(cell);
    };
  };

  /**
   * Copies are appended in render order; put them back in the order of
   * their header cells after cells are added or moved (upstream renders
   * the store's columns in order).
   */
  scheduleStickyReorder(): void {
    if (this.reorderScheduled) return;
    this.reorderScheduled = true;
    schedule('afterRender', () => {
      this.reorderScheduled = false;
      const row = this.stickyRow;
      if (!row || this.isDestroying || this.isDestroyed) return;
      const cells = [...this.stickyCells].filter(
        (cell) => cell.original?.isConnected && cell.copy?.parentNode === row
      );
      cells.sort((a, b) =>
        a.original!.compareDocumentPosition(b.original!) &
        Node.DOCUMENT_POSITION_FOLLOWING
          ? -1
          : 1
      );
      cells.forEach((cell, index) => {
        if (row.children[index] !== cell.copy) {
          row.insertBefore(cell.copy!, row.children[index] ?? null);
        }
      });
    });
  }

  /**
   * On the `<table>`: syncs the sticky header's inline scroll and width
   * with the table (upstream does it in `EuiTableStickyHeader`), watches
   * header cells moving, and observes the scrolling wrapper for the
   * sticky scrollbar.
   */
  setupTable = modifier(
    (
      table: HTMLTableElement,
      [scrollableInline, stickyHeader, stickyScrollbar]: [
        boolean | undefined,
        boolean,
        boolean
      ]
    ) => {
      this.tableElement = table;
      const wrapper = table.parentElement!;
      const cleanups: Array<() => void> = [];

      if (stickyHeader && typeof MutationObserver !== 'undefined') {
        // header cells moved by their parent (e.g. reordered columns)
        const observer = new MutationObserver((records) => {
          if (
            records.some((record) =>
              (record.target as Element).closest?.('thead')
            )
          ) {
            this.scheduleStickyReorder();
          }
        });
        observer.observe(table, { childList: true, subtree: true });
        cleanups.push(() => observer.disconnect());
      }

      if (stickyHeader && scrollableInline) {
        const onScroll = () => {
          if (this.stickyContainer) {
            this.stickyContainer.scrollLeft = wrapper.scrollLeft;
          }
        };
        if (this.stickyTable) {
          this.stickyTable.style.minWidth = `${table.getBoundingClientRect().width}px`;
        }
        wrapper.addEventListener('scroll', onScroll, { passive: true });
        cleanups.push(() => wrapper.removeEventListener('scroll', onScroll));
        if (typeof ResizeObserver !== 'undefined') {
          const observer = new ResizeObserver((entries) => {
            const element = entries[0]?.target;
            if (element && this.stickyTable) {
              this.stickyTable.style.minWidth = `${element.clientWidth}px`;
            }
          });
          observer.observe(table);
          cleanups.push(() => observer.disconnect());
        }
      }

      if (stickyScrollbar) {
        cleanups.push(this.stickyScrollbar.observe(wrapper));
      }

      return () => {
        cleanups.forEach((cleanup) => cleanup());
        if (this.tableElement === table) this.tableElement = undefined;
      };
    }
  );

  @cached
  get wrapperClass(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiTableStyles);
    return euiClass(
      context,
      WRAPPER_CONTAINER,
      this.args.scrollableInline ? styles.scrollableWrapper : undefined
    );
  }

  @cached
  get tableClass(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiTableStyles);
    const { compressed, scrollableInline, tableLayout } = this.args;
    const responsive = this.isResponsive;
    // Same order as upstream's `tableStyles`.
    return euiClass(
      context,
      TABLE_RESET,
      styles.euiTable,
      scrollableInline ? styles.euiTableScrollableInline : undefined,
      styles.layout[tableLayout === 'auto' ? 'auto' : 'fixed'],
      !compressed || responsive ? styles.uncompressed : undefined,
      compressed && !responsive ? styles.compressed : undefined,
      this.hasBackground ? styles.hasBackground : undefined,
      responsive ? styles.mobile : styles.desktop,
      this.args.css
    );
  }

  <template>
    {{#if this.showStickyHeader}}
      <EuiTableStickyHeader
        @table={{this}}
        @compressed={{@compressed}}
        @scrollableInline={{@scrollableInline}}
      />
    {{/if}}
    <div
      class="euiTable__wrapper {{this.wrapperClass}}"
      {{onMediaQueryChange this.query this.onBreakpointChange}}
    >
      <table
        tabindex="-1"
        class="euiTable {{this.tableClass}}"
        ...attributes
        {{this.setupTable
          @scrollableInline
          this.showStickyHeader
          this.showStickyScrollbar
        }}
      >{{yield}}</table>
    </div>
    {{#if this.showStickyScrollbar}}
      <EuiTableStickyScrollbar @state={{this.stickyScrollbar}} />
    {{/if}}
  </template>
}
