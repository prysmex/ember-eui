import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { useEuiBorealisStyles } from '../utils/eui/styles.ts';
import type { EuiCss } from '../utils/eui/styles.ts';
import { euiHeaderBreadcrumbsStyles } from '../utils/eui/styles.generated.ts';
import EuiBreadcrumbs from './eui-breadcrumbs.gts';

import type {
  EuiBreadcrumbsSignature,
  EuiBreadcrumbsType
} from './eui-breadcrumbs.gts';

/** EuiBreadcrumbs styled for the header. */
export interface EuiHeaderBreadcrumbsSignature {
  Element: EuiBreadcrumbsSignature['Element'];
  Args: Omit<EuiBreadcrumbsSignature['Args'], 'max' | 'truncate'> & {
    /**
     * Collapses the breadcrumbs past this number into a "…" item. Defaults
     * to `4` (not `5` as in `EuiBreadcrumbs`); `0` or `null` shows all.
     */
    max?: number | null;
    /** Keeps the breadcrumbs on one line, truncating each. Defaults to `true`, as upstream. */
    truncate?: boolean;
  };
  Blocks: {
    /** See `EuiBreadcrumbs`' `<:popoverContent>`. */
    popoverContent: EuiBreadcrumbsSignature['Blocks']['popoverContent'];
  };
}

/**
 * Upstream `EuiHeaderBreadcrumbs`: `EuiBreadcrumbs` with `max` 4 and
 * truncation, plus `euiHeaderBreadcrumbsStyles` as its `@css` (as upstream).
 * Any other `EuiBreadcrumbs` argument is forwarded, and overrides these
 * defaults.
 */
export default class EuiHeaderBreadcrumbs extends Component<EuiHeaderBreadcrumbsSignature> {
  get max(): number | null {
    return this.args.max === undefined ? 4 : this.args.max;
  }

  /** Defaults to `'application'`, as upstream. */
  get type(): EuiBreadcrumbsType {
    return this.args.type ?? 'application';
  }

  get truncate(): boolean {
    return this.args.truncate ?? true;
  }

  /** The header's styles, then the caller's `@css`. */
  @cached
  get css(): EuiCss {
    const context = getEuiThemeContext(this);
    const header = useEuiBorealisStyles(context, euiHeaderBreadcrumbsStyles)
      .euiHeaderBreadcrumbs;
    return this.args.css ? [header, this.args.css] : header;
  }

  <template>
    <EuiBreadcrumbs
      @max={{this.max}}
      @truncate={{this.truncate}}
      @breadcrumbs={{@breadcrumbs}}
      @responsive={{@responsive}}
      @type={{this.type}}
      @lastBreadcrumbIsCurrentPage={{@lastBreadcrumbIsCurrentPage}}
      class="euiHeaderBreadcrumbs"
      @css={{this.css}}
      ...attributes
    >
      <:popoverContent as |breadcrumb closePopover|>
        {{yield breadcrumb closePopover to="popoverContent"}}
      </:popoverContent>
    </EuiBreadcrumbs>
  </template>
}
