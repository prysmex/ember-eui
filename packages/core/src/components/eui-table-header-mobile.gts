import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';

import {
  BOX_SIZING,
  DEFAULT_TABLE_BREAKPOINT,
  isTableResponsive,
  minBreakpointQuery,
  onMediaQueryChange
} from '../-private/table.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import { euiTableHeaderMobileStyles } from '../utils/eui/styles.generated.ts';

import type { TableResponsiveBreakpoint } from '../-private/table.ts';

/**
 * A bar shown above a responsive `EuiTable` on small screens (where the
 * header row is hidden), e.g. with "select all" and `EuiTableSortMobile`.
 * Like upstream it renders nothing while the table is not in cards.
 */
export interface EuiTableHeaderMobileSignature {
  Element: HTMLDivElement;
  Args: {
    /**
     * Same as the table's `@responsiveBreakpoint`: shown below this named
     * theme breakpoint, always with `true`, never with `false`. Defaults to
     * `'m'`.
     */
    responsiveBreakpoint?: TableResponsiveBreakpoint;
  };
  Blocks: {
    /** The controls. */
    default: [];
  };
}

export default class EuiTableHeaderMobile extends Component<EuiTableHeaderMobileSignature> {
  @tracked private mediaVersion = 0;

  get breakpoint(): TableResponsiveBreakpoint {
    return this.args.responsiveBreakpoint ?? DEFAULT_TABLE_BREAKPOINT;
  }

  @cached
  get query(): string | undefined {
    return minBreakpointQuery(getEuiThemeContext(this).upstream, this.breakpoint);
  }

  @cached
  get isResponsive(): boolean {
    void this.mediaVersion;
    return isTableResponsive(this.breakpoint, this.query);
  }

  onBreakpointChange = (): void => {
    this.mediaVersion++;
  };

  @cached
  get classes(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiTableHeaderMobileStyles);
    return euiClass(context, BOX_SIZING, styles.euiTableHeaderMobile);
  }

  <template>
    {{! while nothing is shown, a hidden marker keeps the breakpoint listener }}
    {{#if this.isResponsive}}
      <div
        class="euiTableHeaderMobile {{this.classes}}"
        {{onMediaQueryChange this.query this.onBreakpointChange}}
        ...attributes
      >{{yield}}</div>
    {{else}}
      <span hidden {{onMediaQueryChange this.query this.onBreakpointChange}}></span>
    {{/if}}
  </template>
}
