import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
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
import {
  EUI_TABLE_CSS_CONTAINER_NAME,
  euiContainerCSS,
  euiTableStyles
} from '../utils/eui/styles.generated.ts';

import type {
  EuiTableContext,
  TableResponsiveBreakpoint
} from '../-private/table.ts';

/**
 * A styled `<table>`, built from `EuiTableHeader`, `EuiTableHeaderCell`,
 * `EuiTableBody`, `EuiTableRow` and `EuiTableRowCell`. These components
 * only render the markup: sorting, selection and pagination stay yours
 * (or come from a headless table library).
 *
 * Like upstream, the table is wrapped in a `div.euiTable__wrapper`;
 * attributes go to the `<table>`.
 */
export interface EuiTableSignature {
  Element: HTMLTableElement;
  Args: {
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
  };
  Blocks: {
    /** The header, body and footer. */
    default: [];
  };
}

const WRAPPER_CONTAINER = euiContainerCSS(
  'normal',
  EUI_TABLE_CSS_CONTAINER_NAME,
  true
);

export default class EuiTable
  extends Component<EuiTableSignature>
  implements EuiTableContext
{
  /** Bumped when the breakpoint query starts or stops matching. */
  @tracked private mediaVersion = 0;

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
      responsive ? styles.mobile : styles.desktop
    );
  }

  <template>
    <div
      class="euiTable__wrapper {{this.wrapperClass}}"
      {{onMediaQueryChange this.query this.onBreakpointChange}}
    >
      <table
        tabindex="-1"
        class="euiTable {{this.tableClass}}"
        ...attributes
      >{{yield}}</table>
    </div>
  </template>
}
